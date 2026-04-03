# Affirmation Alarm

A native iOS app that wakes you up with AI-generated personalized affirmations. Set an alarm, tell the app your goals, and every morning you'll hear a custom motivational sequence tailored just for you.

## What It Does

1. **Onboarding**: Enter your name, type your personal goals, pick focus areas, and choose how many affirmations you want (1-5)
2. **Alarm fires**: A notification wakes you up — tap it to open the app
3. **Affirmation sequence begins**:
   - Alarm sound plays for a configurable duration (3-15 seconds, default 10)
   - "Good Morning, [Your Name]"
   - 1-5 personalized affirmations based on YOUR specific goals (spoken aloud via TTS)
   - "Take a deep breath into your heart... you are worthy of everything you desire, [Name]"
   - A dynamic, AI-generated motivational closing (varies each day)
4. **Favorite affirmations**: Tap the heart on any affirmation to save it — favorites repeat in every alarm until removed
5. **Start your day** feeling motivated and focused

## Setup Instructions

### Prerequisites
- Mac with Xcode 26+ installed
- iPhone or iOS Simulator running iOS 17+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (recommended): `brew install xcodegen`
- An Anthropic API key from [console.anthropic.com](https://console.anthropic.com)

### Option A: Using XcodeGen (Recommended)

```bash
cd AffirmationAlarm
xcodegen generate
open AffirmationAlarm.xcodeproj
```

### Option B: Manual Xcode Setup

1. Open Xcode and create a new iOS App project named "AffirmationAlarm" with SwiftUI
2. Set deployment target to iOS 17.0
3. Delete the auto-generated ContentView.swift
4. Drag the `AffirmationAlarm/` source folder into the project
5. In Signing & Capabilities, add "Background Modes" (enable Background fetch and Audio)
6. In Signing & Capabilities, add "Time Sensitive Notifications"
7. Build and run

### Setting Your API Key

You have two options:

**Option 1 (Recommended): In-App Settings**
1. Launch the app and complete onboarding
2. Go to Settings > API Key
3. Enter your Anthropic API key
4. It's stored securely in the iOS Keychain

**Option 2: Config File**
1. Copy `AffirmationAlarm/Resources/Config.plist.example` to `AffirmationAlarm/Resources/Config.plist`
2. Replace `YOUR_API_KEY_HERE` with your actual key
3. The `Config.plist` file is gitignored

## Adding Custom Alarm Sounds

The app supports custom alarm sounds in CAF format. To convert audio files:

```bash
# Convert WAV to CAF
afconvert input.wav output.caf -d aac -f caff

# Convert MP3 to CAF
afconvert input.mp3 output.caf -d aac -f caff
```

Place the `.caf` files in `AffirmationAlarm/Resources/` and they'll appear in the sound picker.

## Architecture

- **SwiftUI + SwiftData** (iOS 17+)
- **MVVM** pattern
- **AVSpeechSynthesizer** for text-to-speech
- **UNUserNotificationCenter** for alarm scheduling
- **Claude API** (Anthropic Messages API via Opus 4.6) for generating personalized affirmations

## Important iOS Notes

- **Do Not Disturb**: For the alarm to work reliably, add this app to your Focus mode's "Allowed Apps"
- **Text-to-speech** only plays when you open the app (tap the notification). It cannot play in the background
- **Affirmations are cached**: The app pre-generates affirmations so they work even without internet
