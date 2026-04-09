# Release Notes

## 1.0.0 — First public build

The first version of Affirmation Alarm.

**Wake up to your own voice.**

- Personalized morning alarms that speak your name and 3 AI-crafted
  affirmations, tailored to your goals
- Six natural voices to choose from — preview each one with your own
  name before you commit
- Built on iOS 26's AlarmKit, so alarms ring through silent mode,
  Focus, and Do Not Disturb
- Custom snooze schedules a 10-minute follow-up alarm with a different
  spoken prompt to get you out of bed
- Tap Stop mid-ring and hear a gentle closing statement instead of a
  hard cut-off
- Offline fallback — a bundled affirmation pool keeps your morning
  personal even when you're on airplane mode
- All data lives on your device. No accounts, no tracking, no ads.

*Requires iOS 26.0 or later.*

---

## TestFlight notes (for each build — paste into App Store Connect)

### Build 1 — Initial TestFlight

First build uploaded to TestFlight. This is the baseline stop/snooze +
pre-render pipeline + voice picker + home-screen affirmations flow.

Please test:

1. Complete onboarding with your real name
2. Wait ~10 seconds for the "Preparing your first morning" banner to clear
3. Create an alarm 1 minute in the future
4. Lock your device and wait for it to ring
5. Listen for "Good morning, [your name]" followed by affirmations
6. Tap Stop → should play a brief closing statement, app stays closed
7. Try again with a different voice via Settings → Voice Settings
8. Try snoozing an alarm → follow-up should ring 10 minutes later

Known limitation: the selected alarm tone "beep" that's supposed to
precede the snooze follow-up voice is not yet implemented — the snooze
follow-up currently plays the voice only, no beep in front. Planned
for a later build.

Please file any bugs via the repo's issue tracker, with: device model,
iOS version, steps to reproduce, and the first 10 lines of Console.app
logs filtered by `com.cgibson.affirmationalarm`.
