# Affirmation Alarm — TestFlight & App Store Submission Checklist

A human-driven checklist for everything you need to do before hitting
"Submit for Review" in App Store Connect. Work top to bottom. Most items
are one-time setup; once completed, subsequent submissions only need the
"Release notes + Build & upload" sections.

---

## 🔑 One-time setup (do once, then forget)

### Apple Developer Account
- [ ] Active, paid Apple Developer Program membership (`developer.apple.com`)
- [ ] Team ID matches the one baked into `AffirmationAlarm/project.yml`: **`JLYXS97L8A`**. If yours is different, update `DEVELOPMENT_TEAM` in project.yml + `teamID` in `codemagic.yaml` ExportOptions.

### App Store Connect app record
- [ ] Create the app at https://appstoreconnect.apple.com → My Apps → **+** → New App
- [ ] Platforms: **iOS**
- [ ] Bundle ID: **`com.cgibson.affirmationalarm`** (must match project.yml exactly)
- [ ] SKU: anything unique — suggestion `AFFIRMATION-ALARM-001`
- [ ] User Access: Full Access (recommended)
- [ ] Save — the app record now exists even if no build has been uploaded yet

### App Store Connect API Key (for CodeMagic)
- [ ] Go to https://appstoreconnect.apple.com/access/api → **+** → Generate API Key
- [ ] Name: `Codemagic CI`
- [ ] Access: **App Manager** (minimum required for TestFlight uploads)
- [ ] Download the `.p8` file immediately — you only get one chance
- [ ] Copy the **Issuer ID** from the top of the API Keys page
- [ ] Copy the **Key ID** from the new key's row

### CodeMagic secrets
- [ ] In `codemagic.io` → your app → Environment variables, create a group called **`appstore_credentials`** (exact name — `codemagic.yaml` references it)
- [ ] Add these vars, mark ALL as **Secure**:
  - `APP_STORE_CONNECT_ISSUER_ID` — from the previous step
  - `APP_STORE_CONNECT_KEY_IDENTIFIER` — the Key ID
  - `APP_STORE_CONNECT_PRIVATE_KEY` — contents of the `.p8` file (paste the full PEM including `-----BEGIN` / `-----END` lines)
  - `ANTHROPIC_API_KEY` — your Claude API key
  - `OPENAI_API_KEY` — your OpenAI API key (used for TTS)
  - `SENTRY_DSN` — your Sentry DSN (optional; if omitted, crash reporting silently no-ops)

### Sentry (optional but recommended)
- [ ] Create a free Sentry account at https://sentry.io
- [ ] Create a new project, platform: **Apple / iOS**, project name: `affirmation-alarm`
- [ ] Copy the DSN (starts with `https://...@...ingest.sentry.io/...`)
- [ ] Add it to CodeMagic as `SENTRY_DSN` (secret) — see previous step
- [ ] Without this, the app still runs; Sentry initialization is guarded and silently skips when the DSN is missing

### Privacy policy hosting
- [ ] Take the text in `PRIVACY.md` (this repo), paste it into a hosted page:
  - **Option A:** GitHub Pages on this repo (Settings → Pages → Source: `main` branch, `/docs` folder; move PRIVACY.md into `docs/index.md`)
  - **Option B:** Any static host — Cloudflare Pages, Netlify, Vercel, etc.
- [ ] You need a stable public URL to paste into App Store Connect. It MUST be reachable from Apple's reviewers' IPs (no geo-blocking)
- [ ] Note the final URL — you'll paste it into App Store Connect's "Privacy Policy URL" field

---

## 📝 Metadata (App Store Connect → App Information + App Store tab)

Everything below is drafted in `AppStoreMetadata.md`. Copy-paste the fields
from there into App Store Connect. Items marked **REQUIRED** are blocking.

### App Information tab
- [ ] **Name**: (from `AppStoreMetadata.md`)
- [ ] **Subtitle**: (from `AppStoreMetadata.md`)
- [ ] **Primary Language**: English (U.S.)
- [ ] **Bundle ID**: `com.cgibson.affirmationalarm` (pre-populated after create)
- [ ] **SKU**: (from one-time setup)
- [ ] **Primary Category**: Lifestyle
- [ ] **Secondary Category**: Health & Fitness
- [ ] **Privacy Policy URL**: **REQUIRED** — the URL from the previous step

### App Store tab → Version info (1.0)
- [ ] **Promotional Text** (170 char max)
- [ ] **Description** (4000 char max)
- [ ] **Keywords** (100 char max, comma-separated)
- [ ] **Support URL**: a working URL where users can reach you (can be a Twitter/Mastodon profile, or a GitHub issues page)
- [ ] **Marketing URL** (optional): a landing page if you have one
- [ ] **Copyright**: `© 2026 Colin Gibson` (or your preferred attribution)
- [ ] **Age Rating**: run the questionnaire — should come out as **4+** (no objectionable content)

### Screenshots (REQUIRED — blocking)
You need at least one set of screenshots for the largest iPhone display size currently supported. Capture them on a real device or via Xcode's simulator → Device → Screenshots menu.

- [ ] **6.9" iPhone** (e.g., iPhone 16 Pro Max) — 1320 × 2868 px
- [ ] **6.5" iPhone** (e.g., iPhone 11 Pro Max) — 1242 × 2688 px (optional if you supply 6.9")
- [ ] Suggested screenshot framing (capture these screens):
  1. Home screen with `TodayAffirmationsCard` showing personalized affirmations
  2. Voice picker in Settings with 6 voices visible
  3. Alarm detail view with time wheel + sound preview
  4. The alarm ringing UI on the lock screen (harder to capture — fake via screenshot on device)
  5. A view showing the greeting message with the user's name

### App Review Information
- [ ] **First Name / Last Name**: your name
- [ ] **Phone**: a number Apple can reach during review
- [ ] **Email**: a reliable inbox
- [ ] **Demo Account**: N/A — the app has no login
- [ ] **Notes**: *"This app uses AlarmKit (iOS 26) to schedule personalized alarms. To verify the full experience on your review device: (1) complete onboarding with any name, (2) wait 60 seconds for the TTS audio to pre-render, (3) set an alarm for 1 minute out, (4) lock the device and wait for it to ring. The alarm will play a personalized voice greeting + 3 AI-generated affirmations. Tap Stop to hear a closing statement. Tap Snooze for a 10-minute follow-up alarm with a different voice message."*

### App Privacy (REQUIRED — blocking)
App Store Connect asks a questionnaire about data collection. Based on the `PrivacyInfo.xcprivacy` file + `PRIVACY.md`:
- [ ] Do you or your third-party partners collect data from this app? **Yes** (because we send text to Claude + OpenAI)
- [ ] Data types collected:
  - **User Content** → **Other User Content** (the affirmation text and user's profile goals sent to Claude)
- [ ] Is this data linked to the user? **No** (we don't send device IDs, email, or any stable identifier; Claude + OpenAI receive anonymous text)
- [ ] Is this data used for tracking? **No**
- [ ] Is this data used for app functionality? **Yes** (to generate the affirmations and speak them aloud)

---

## 🏗️ Build & upload

### Pre-flight (every submission)
- [ ] Pull latest `main` locally
- [ ] Bump `MARKETING_VERSION` in `AffirmationAlarm/project.yml` if the release is a new version (e.g., 1.0.0 → 1.0.1 or 1.1.0)
- [ ] CodeMagic auto-increments `CURRENT_PROJECT_VERSION` (the build number) in its pipeline — no manual bump needed
- [ ] Push to `main` (or the release branch) — CodeMagic picks up the push

### CodeMagic workflows
- [ ] **`ios-simulator-build`** runs automatically on every push. It compiles for simulator without code signing. If this fails, the TestFlight workflow will also fail — fix the red first.
- [ ] **`ios-testflight`** runs only on pushes to the branch pattern declared in `codemagic.yaml` (currently `claude/ios-app-development-faMqt` — update to `main` when you're ready for real releases). This is the workflow that actually signs and uploads.
- [ ] Each run takes 15-30 min. Watch the live log the first time through so you catch any new failures.

### After upload
- [ ] In App Store Connect → TestFlight, wait ~10 min for the build to finish processing
- [ ] Add test notes for this build (what changed since last time)
- [ ] Submit to TestFlight review — usually a few hours for first build, minutes for updates
- [ ] Add internal testers (up to 100 emails, no Apple review required)
- [ ] For external testers (up to 10,000), Apple needs to review the build first — usually approves within 24h

---

## ✅ Before clicking "Submit for Review" (App Store, not TestFlight)

Once you've TestFlighted a build and it passes, you submit it to the App Store from the same build.

- [ ] All metadata fields above are filled
- [ ] Screenshots are uploaded
- [ ] Privacy policy URL resolves
- [ ] Age rating questionnaire completed
- [ ] App Privacy questionnaire completed
- [ ] Export Compliance: **Yes, uses encryption** → HTTPS standard encryption, uses exempt encryption
- [ ] Content Rights: I have not owned or licensed third-party content → depends on whether you consider the bundled alarm tones (alarm_gentle.caf etc.) to be third-party content; if you made them yourself or have royalty-free licenses, check the box affirmatively
- [ ] Review notes on the build include the testing steps above
- [ ] You're pushing the correct build number — double-check the version + build in the submission screen

---

## 🧪 Real-device verification before submission

Before submitting the final TestFlight build to App Store review, run this 10-step verification on a real iOS 26 device:

1. **Stop mid-affirmation plays the closing.** Set an alarm 1 min out. When it rings, wait for ~affirmation 2 to start, then tap Stop. Expected: voice cut mid-word → closing statement plays → silence. App does not open.

2. **Stop during the closing (edge case).** Let an alarm play to the end of the affirmations portion (~15s) and tap Stop. The closing plays once. No double-closing.

3. **Stop at the very start.** Tap Stop within the first second. Greeting cuts, closing plays cleanly.

4. **Snooze fires follow-up.** Set an alarm 1 min out. Tap Snooze. Wait 10 min. Second alarm fires with *"Time to get up, [Name]. Let's have a great day."* in the chosen voice. Follow-up has a Stop button only (no Snooze).

5. **Snooze follow-up dismisses cleanly.** Tap Stop on the follow-up. Silent dismissal (no closing file rendered for the follow-up's fresh UUID, intent no-ops gracefully).

6. **Pre-render produces three files.** After onboarding completes, check `Library/Sounds/` via Xcode's Devices & Simulators → your device → AffirmationAlarm → Download Container. Confirm `morning-<alarmID>.wav`, `closing-<alarmID>.wav`, `snooze-<alarmID>.wav` all exist.

7. **Voice change regenerates all three files.** Settings → Voice Settings → select a different voice → watch the three files get overwritten with new mtime.

8. **Home screen shows today's affirmations.** Complete the morning alarm. Re-open the app. `TodayAffirmationsCard` shows the 3 affirmations that were spoken during the ring. Tap heart on one → it appears in Favorites.

9. **Offline fallback works.** Airplane Mode → set an alarm 1 min out. The alarm rings with the bundled `.caf` tone (no rendered file could be written). Stop tap dismisses cleanly with no closing (no `closing-*.wav` either). Snooze still works — fallback is `.default` AlarmKit sound.

10. **Bundled affirmation pool works when Claude fails.** Set `ANTHROPIC_API_KEY` to an invalid value in Info.plist (temporarily, for this test) → force a re-render via voice change → verify the WAV contains affirmations from `BundledAffirmationPool.affirmations` instead of generic placeholders. Revert the API key after the test.

---

## 🚨 Known caveats

- **AlarmKit doesn't fire in the simulator.** You must test the ring flow on a real device. The simulator build catches compile errors but can't verify alarm behavior.
- **First-launch TTS latency is ~5-10 seconds.** Users will see the "Preparing your first morning" banner on HomeView while it runs. This is expected; if it hangs for more than 30 seconds, check Console.app for `com.cgibson.affirmationalarm` subsystem logs.
- **OpenAI TTS costs.** Each alarm render = 2-3 TTS calls (main, closing, snooze voice) at ~$0.00004 per call. Worst-case ~$0.0001 per day per user. Negligible at any scale you'd TestFlight.
- **AlarmKit 30-second sound cap.** The `morning-*.wav` files are capped at ~65 words (≈25 seconds) to stay under the cap. Claude is prompted for 12-15 word affirmations to fit.
