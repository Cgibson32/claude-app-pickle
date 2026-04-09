# Privacy Policy — Affirmation Alarm

**Last updated: April 9, 2026**

This is the privacy policy for Affirmation Alarm, an iOS application. It
describes what data the app handles, what stays on your device, what gets
sent to third parties, and why.

## Summary

- **No accounts, no sign-in, no ads, no tracking.** The app does not collect
  any personal identifiers, advertising IDs, device IDs, analytics events,
  or behavioral data about you.
- **Your profile and alarms stay on your device.** Your name, goals,
  categories, favorite affirmations, alarm schedules, evening reflections,
  gratitude entries, and daily intentions are all stored locally in the
  app's database (Apple's SwiftData framework) inside your app container.
  They never leave your device except when you're generating new morning
  affirmations (see below).
- **We send anonymous text to two third-party services** — Claude
  (Anthropic) and OpenAI — when the app generates your morning audio.
  No identifiers are attached.
- **We include a bundled affirmation pool as an offline fallback.** If
  those third-party services are unreachable, the app generates affirmations
  from a hardcoded list bundled with the app. Nothing goes over the network
  in that case.

## What the app does with your data

### Stays on your device (local only)

The app stores the following in your device's app-private database. These
never leave your device unless transmitted to Claude (see next section):

- Your first name
- Your free-text goals (whatever you typed during onboarding)
- The focus categories you selected
- Your chosen voice preference (Nova, Shimmer, Fable, etc.)
- Your alarm schedules (time, weekday pattern, label, selected tone)
- Your affirmation history — all affirmations the app has generated or
  that you've typed manually
- Your favorites (heart/checkmark marked affirmations)
- Your gratitude entries, daily intentions, and evening reflections

If you delete the app, iOS erases this data along with the app.

### Sent to Claude (Anthropic) for affirmation generation

When the app generates your morning affirmations, it sends a text-only
prompt to Anthropic's Claude API containing:

- Your first name (for personalization, e.g., "Good morning, Sarah")
- Your free-text goals
- Your selected focus categories
- Up to three recent gratitude entries (if you've logged any)
- Up to three recent daily intentions (if you've logged any)
- Up to three recent evening reflection notes (if you've logged any)
- The number of affirmations you've asked for

Claude returns a JSON response containing the generated affirmations and
a closing message. Anthropic processes this data under their terms at
https://www.anthropic.com/legal/privacy. The request does NOT include your
device ID, advertising ID, IP-based location, email, or any stable
identifier — Anthropic sees the text and the app's API key, nothing else.

### Sent to OpenAI for voice synthesis

When the app generates the audio the alarm will play, it sends the
generated affirmation text to OpenAI's Text-to-Speech API so OpenAI's
`nova` voice (or whichever voice you've chosen) can speak it aloud. OpenAI
processes this data under their terms at
https://openai.com/policies/privacy-policy. As with Claude, no device
identifier or personal information is attached beyond the text itself and
the app's API key.

The returned audio file is saved locally to your app's private sandbox
folder (`Library/Sounds/`) and is played by iOS's alarm system at the
scheduled time. It's never uploaded anywhere.

### Never collected

The app does not collect, transmit, or otherwise process:

- Your email address, phone number, or real name beyond the first name
  you type during onboarding (which stays on-device for greeting purposes)
- Your location (precise or coarse)
- Your contacts, photos, microphone input, or camera
- Your Apple ID, IDFA, IDFV, or any other device identifier
- Crash reports or analytics events *(unless you're in the opt-in Sentry
  crash-reporting beta — see the next section)*
- Your browsing activity, keystrokes, or interactions with other apps

## Optional: crash reporting

This app may include Sentry crash reporting to help the developer identify
and fix crashes. If enabled, Sentry captures:

- Stack traces when the app crashes
- The app version and iOS version
- An anonymous device identifier randomly generated per install

Sentry does NOT capture any of your on-device data, profile, affirmations,
or audio. You can disable crash reporting by deleting and reinstalling the
app — the anonymous install ID regenerates on reinstall.

Sentry's privacy policy: https://sentry.io/privacy/

## Your rights

Because the app doesn't have accounts and doesn't transmit any stable
identifier tied to you, there is no user record to delete or export on our
servers. Your data lives on your device. To delete all of it, delete the
app from your device — iOS erases it along with the app.

If you're in a jurisdiction with GDPR, CCPA, or similar rights and would
like information about the processing that happens at Anthropic or OpenAI
specifically, consult their privacy policies directly — they are the data
processors for the brief text transmission described above.

## Changes to this policy

If this policy changes, the new version will be committed to this
repository and the "Last updated" date above will reflect the change.

## Contact

If you have questions about this policy, open an issue on this repository
or contact the developer through the support URL listed in the App Store.
