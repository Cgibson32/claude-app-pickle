# Affirmation Alarm

A native iOS app that wakes you up with AI-generated personalized affirmations. Set an alarm, tell the app your goals, and every morning you'll hear a custom motivational sequence tailored just for you.

## What It Does

1. **Onboarding**: Enter your name, type your personal goals, and pick focus areas
2. **Alarm fires**: Your phone plays an alarm sound 1-2 times
3. **Tap to start**: A full-screen sequence begins:
   - "Good Morning, [Your Name]"
   - 3-5 personalized affirmations based on YOUR specific goals (spoken aloud)
   - "Take a deep breath into your heart... you are worthy of everything you desire, [Name]"
   - "Have a wonderful day, [Name]"
4. **Start your day** feeling motivated and focused

## Setup Instructions

### Prerequisites
- Mac with Xcode 15+ installed
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

The app supports custom alarm sounds in CAF format (max 30 seconds). To convert audio files:

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
- **Claude API** (Anthropic Messages API) for generating personalized affirmations

## Important iOS Notes

- **Do Not Disturb**: For the alarm to work reliably, add this app to your Focus mode's "Allowed Apps"
- **Notification sounds** are limited to 30 seconds by iOS. The app schedules two notifications (35 seconds apart) to simulate ringing twice
- **Text-to-speech** only plays when you open the app (tap the notification). It cannot play in the background
- **Affirmations are cached**: The app pre-generates affirmations so they work even without internet
