# Rise Alarm — Architecture Notes

This document captures the architectural decisions and iOS constraints
that shaped the app. Read before making structural changes.

## What the app does

An alarm app that wakes users with a **musical alarm sound** (from one
of several bundled Suno-generated tracks) and, when the user opens the
app, plays **personalized affirmations + a random wake-up song**.

## iOS constraints (read these first)

### 1. `AlarmKit` requires bundled CAF for the alarm sound

`AlertConfiguration.AlertSound.named()` only reliably reads audio files
from `Bundle.main`. Audio in `Library/Sounds/` silently falls back to
`.default` on iOS 26.3.1 (FB19779004, unresolved as of mid-2026).

**Implication:** We cannot use dynamically-rendered (personalized)
audio as the alarm sound. The alarm sound must be a static file
shipped in the bundle.

**Solution:** Bundle 30-second Suno-generated musical wake-ups as the
alarm sounds (`alarm_rise.caf`, `alarm_toast.caf`, etc.). The user
hears a pleasant musical wake-up from the lock screen even when the
app process is dead.

### 2. Background process suspension is real

iOS suspends backgrounded apps after a few seconds without active audio
playback. The standard workaround (silent audio loop on
`UIBackgroundModes: audio`) is fragile:

- AlarmKit's daemon uses a non-mixable audio category, interrupting
  our silent session when the alarm fires
- The `.ended` interruption notification can arrive too late to
  prevent suspension
- Phone calls, Siri, and exclusive-audio apps can interrupt us

**Implication:** We CANNOT guarantee that `handleFire` (the observer
that takes over to play affirmations) runs at alarm-fire time.

**Mitigations:**
- `BackgroundKeepAlive` aggressive recovery: on interruption `.began`,
  immediately attempt to resume + spin a tight retry loop (every 500ms
  for 30s) to grab the audio session back the moment AlarmKit releases
- Periodic health check (every 30s) that restarts silent playback if
  it stopped without notification
- **Fallback path:** When `handleFire` doesn't run, the user hears the
  musical alarm sound from the lock screen, taps the Live Activity's
  Stop button, the app foregrounds, and `playFromForegroundRetry`
  plays affirmations with the ringing overlay shown

### 3. Lock-screen widget = Live Activity

The Stop/Snooze buttons on the lock screen come from two sources:
- AlarmKit's built-in system alert (always renders for AlarmKit alarms)
- Our Live Activity widget (`AlarmLiveActivityWidget`), which renders
  alongside the system alert when `AlarmAttributes<AffirmationAlarmMetadata>`
  is registered

Both must remain in sync — the same alarmID flows through both UIs
and both call the same intents.

## Architecture

### Audio flow

```
Alarm fires
  │
  ├─► AlarmKit daemon plays bundled CAF (alarm_rise.caf, 30s music)
  │   (this is what the user hears on the lock screen, always)
  │
  ├─► Live Activity widget renders on lock screen
  │   (Stop/Snooze buttons via AlarmLiveActivityWidget)
  │
  ├─► IF app process alive:
  │     observer.alarmUpdates emits .alerting
  │       → AlarmKitScheduler.route() → handleFire()
  │       → cancels system alarm (musical CAF stops at ~500ms)
  │       → runPlaybackWithOverlay(): shows ringing UI,
  │         plays personalized greeting + affirmations + closing + song
  │
  └─► IF app process dead/suspended:
        musical CAF plays uninterrupted (30s loop) from lock screen
        → user taps Stop on Live Activity
        → StopAndPlayClosingIntent runs, sets pendingMorningPlayback flag
        → app foregrounds (openAppWhenRun = true)
        → checkPendingMorningPlayback → scheduler.playFromForegroundRetry()
        → runPlaybackWithOverlay() shows ringing UI + plays affirmations
```

### Initial alarm sequence (when handleFire runs)

1. Intro chime (`alarm_gentle.caf`, 3s, fades out)
2. Birds intro (`alarm_birds.caf` prepended to TTS at render time, ~3s)
3. Greeting: "Good morning, [name]"
4. N affirmations (user-configured count, freshly generated daily)
5. Closing message
6. Random wake-up song from `WakeUpSongs/` (M4A, avoids recent repeats)

### Snooze follow-up sequence

1. Greeting variant (1 of 5): "Alright, time to get up, [name]!"
2. Random wake-up song from `WakeUpSongs/` (different from morning's)

No affirmations on snooze — the user already heard them 9 minutes ago.

## Key files

| File | Purpose |
|---|---|
| `AlarmKitScheduler.swift` | Schedules alarms, observes fires, routes to playback |
| `AlarmAudioPlayer.swift` | Plays affirmations + songs; serializes via actor |
| `MorningAudioRenderer.swift` | TTS-renders affirmation MP3s to `Library/Sounds/` |
| `WakeUpSongLibrary.swift` | Discovers + randomly picks from bundled `WakeUpSongs/` |
| `BackgroundKeepAlive.swift` | Silent audio loop + aggressive interruption recovery |
| `AlarmLiveActivityWidget.swift` | Lock-screen Stop/Snooze UI |
| `StopAndPlayClosingIntent.swift` | Lock-screen Stop handler (intent → flag → foreground) |
| `SnoozeMorningIntent.swift` | Lock-screen Snooze handler (intent → reschedule) |

## Adding new wake-up songs

1. Drop the audio file (`.mp3`, `.m4a`, `.caf`, or `.wav`) into
   `AffirmationAlarm/Resources/Sounds/WakeUpSongs/`
2. Push — XcodeGen + Codemagic handle the rest. No code changes needed
3. The library is auto-discovered at runtime by `WakeUpSongLibrary.allSongs()`

## Adding new musical alarm sounds (lock-screen wake-up)

1. Use ffmpeg to convert to 30-sec mono PCM CAF (the format AlarmKit needs):
   ```
   ffmpeg -i source.m4a -ss 0 -t 30 \
     -af "afade=t=in:st=0:d=1.5,afade=t=out:st=28.5:d=1.5" \
     -c:a pcm_s16be -ar 44100 -ac 1 \
     AffirmationAlarm/AffirmationAlarm/Resources/Sounds/alarm_NAME.caf
   ```
2. Add to `AppConstants.AlarmSound` enum in `Constants.swift`
3. No XcodeGen config needed — Resources/Sounds/ is already in the
   build's source path

## Pitfalls to avoid

1. **Don't put dynamic audio in the alarm sound.** Bundle only.
2. **Don't expect `handleFire` to always run.** Always have a foreground
   fallback path (`playFromForegroundRetry`).
3. **Don't deactivate the audio session after affirmation playback.**
   `BackgroundKeepAlive` needs it active.
4. **Don't add the WakeUpSongs folder as a Group in Xcode.** It must
   be a Folder Reference (or via `type: folder` in `project.yml`) so
   `Bundle.urls(subdirectory:)` can find the songs.
5. **Don't skip the ringing overlay in the foreground retry path.**
   Users need Stop/Snooze available during playback.
