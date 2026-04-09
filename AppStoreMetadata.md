# App Store Metadata — Affirmation Alarm

Copy-paste these fields into App Store Connect when you're ready to
submit. All counts are Apple's current limits (as of 2026).

---

## App Information

**Name** (30 chars max)
```
Affirmation Alarm
```

**Subtitle** (30 chars max)
```
Wake up to your own voice
```

**Primary Category**
- Lifestyle

**Secondary Category**
- Health & Fitness

**Content Rights**
- Does not use third-party content
- (Assumes the bundled alarm tones are either your own original audio or royalty-free licensed. If they're from a third party, check the affirmative box and provide the license.)

**Age Rating**
- 4+ (no objectionable content — gentle affirmations, no graphic content, no user-generated content exposure)

---

## App Store Version Info

### Promotional Text (170 chars max, editable between releases without re-review)
```
Wake up to a voice that knows your name. Affirmation Alarm rings with AI-crafted affirmations in a warm, natural voice — tailored to your goals every morning.
```

### Description (4000 chars max)
```
Affirmation Alarm replaces your morning alarm tone with something better: your name, spoken gently, followed by affirmations written for YOUR goals — in a warm, natural-sounding voice.

No more jarring beeps. No more generic motivational quotes. When your alarm fires, you wake up to "Good morning, [Your Name]" and three personalized affirmations, all in a nurturing voice you picked yourself.

━━━━━━━━━━━━━━━━━━━━
WHY IT'S DIFFERENT
━━━━━━━━━━━━━━━━━━━━

• Built on iOS 26's AlarmKit — rings through silent mode, Focus, and Do Not Disturb, just like the built-in Clock app
• AI-generated affirmations tailored to the goals you enter — not a static pool of generic lines
• Six natural voices to choose from (warm, gentle, conversational, grounded) — preview them with your own name before you commit
• Snooze for 10 minutes and wake up to a follow-up "Time to get up" message in the same voice
• Tap Stop mid-ring and hear a gentle closing statement instead of an abrupt cut-off
• Works offline — a bundled library of affirmations steps in if your connection drops
• Your data stays on your device. No accounts, no tracking, no ads.

━━━━━━━━━━━━━━━━━━━━
THE RITUAL
━━━━━━━━━━━━━━━━━━━━

1. Tell us your name, your goals, and what you're focused on
2. Pick a voice you'd want to wake up to — we'll preview it speaking your name
3. Set your alarm time and weekday pattern
4. Every morning, wake up to a personalized voice greeting + 3 affirmations + a gentle closing

The audio is generated fresh every day, shaped by any reflections or gratitude notes you log in the evening. The more you use it, the more tailored the morning ritual becomes.

━━━━━━━━━━━━━━━━━━━━
PRIVACY
━━━━━━━━━━━━━━━━━━━━

Your profile, alarms, and affirmation history live on your device. When we generate new content, we send the minimum text needed to Anthropic's Claude and OpenAI's TTS — no device ID, no account info, no location. See the full policy at the link below.

━━━━━━━━━━━━━━━━━━━━
REQUIREMENTS
━━━━━━━━━━━━━━━━━━━━

iPhone running iOS 26.0 or later. Internet connection recommended for personalized affirmations; offline fallback included.
```

### Keywords (100 chars max, comma-separated, no spaces after commas)
```
affirmation,alarm,morning,voice,ai,wake,mindful,gratitude,routine,personalized,speak,ritual
```

### Support URL
```
https://github.com/Cgibson32/claude-app-pickle/issues
```
*(Replace with a real support URL if you have one — a Twitter/X profile, website, or Discord server also works. Must be publicly accessible.)*

### Marketing URL (optional)
```
(leave blank for v1 unless you have a landing page)
```

### Copyright
```
© 2026 Colin Gibson
```
*(Replace with your preferred attribution.)*

---

## App Privacy (the questionnaire in App Store Connect)

Apple walks you through this interactively. Based on the `PrivacyInfo.xcprivacy`
and `PRIVACY.md` files in this repo:

### Do you or your third-party partners collect data from this app?
**Yes**
*(Because we send affirmation text to Claude + OpenAI for processing.)*

### Data Types Collected

Add only this one category:

**User Content → Other User Content**
- **Collection purpose:** App Functionality
- **Used for tracking?** No
- **Linked to user identity?** No
  - *Rationale: the app doesn't have user accounts and doesn't attach any stable identifier to the text. Claude and OpenAI receive the text and our bundled API key, nothing tied to the specific user.*

### Everything else
- **Contact Info:** None collected
- **Health & Fitness:** None
- **Financial Info:** None (aside from Apple's own StoreKit subscription flow, which Apple handles directly — you don't declare it here)
- **Location:** None
- **Sensitive Info:** None
- **Contacts:** None
- **User Content → Photos, Videos, Audio Data, Gameplay Content, Customer Support, Emails, Messages:** None
- **Browsing History:** None
- **Search History:** None
- **Identifiers:** None
- **Purchases:** None
- **Usage Data:** None
- **Diagnostics:** None *(unless you enable Sentry with a custom identifier, in which case add Crash Data → linked to anonymous device ID → for app functionality)*
- **Other Data Types:** None

---

## Review Notes (for the App Review Information box)

```
This app uses iOS 26's AlarmKit framework to schedule personalized alarms that ring through silent mode. To verify the full experience on your review device:

1. Complete the onboarding flow with any name (e.g., "Reviewer")
2. Wait about 10 seconds on the home screen while the app generates your first morning audio (a banner will show "Preparing your first morning")
3. Tap "Alarms" and set a new alarm for 1 minute in the future
4. Lock the device and wait
5. When the alarm rings, it will play a personalized voice greeting + 3 AI-generated affirmations
6. Tap "Stop" to hear a brief closing statement, or "Snooze" to schedule a 10-minute follow-up

The app generates affirmations via Anthropic's Claude API and synthesizes the voice via OpenAI's Text-to-Speech API. API keys are bundled with the build — no reviewer-side setup needed.

The app does not use user accounts, does not track users, and stores all personal data locally. See the privacy policy URL for details.

If the test alarm does not ring, please check that:
- Alarm permissions have been granted (the app will prompt on first alarm creation)
- iOS 26.0 or later is installed (lower versions are not supported — AlarmKit is iOS 26+ only)
```

---

## Screenshot plan

You need at least 3 screenshots per device size. Recommended order:

1. **Home screen with TodayAffirmationsCard populated** — shows the warm gradient, greeting with user's name, and 3 personalized affirmations with favorite buttons. Hero shot.
2. **Voice picker (Settings → Voice Settings)** — shows the 6 voices with names + taglines and the checkmark on the active voice. Differentiator shot.
3. **Alarm detail view** — time wheel, weekday selector, sound picker. Functional shot showing it's a real alarm clock.
4. **(Optional) The alarm ringing on the lock screen** — hardest to capture, most compelling. Screenshot the lock screen during a test alarm fire.
5. **(Optional) Onboarding name entry** — shows the soft visual style and first-impression tone.

### Suggested caption overlays (Apple supports overlay text on screenshots)

1. "Wake up to your name."
2. "Six voices to choose from. Preview them with your own name."
3. "Set your morning. Keep your weekends."
4. "No jarring beeps. Just affirmations in a voice you love."
5. "Your ritual, your words, your day."

### Device sizes required

Apple requires at least the current-largest-iPhone screenshot set. Provide 6.9" (iPhone 16 Pro Max / 1320 × 2868) and optionally 6.5" (iPhone 11 Pro Max / 1242 × 2688). Smaller sizes are auto-generated by Apple.
