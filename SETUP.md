# Setup Instructions

## Prerequisites
1. Flutter SDK installed
2. Android Studio / VS Code with Flutter extension
3. Android device or emulator
4. Firebase project created

## Firebase Configuration

### Already Completed ✅
- `google-services.json` is present in `android/app/`

### Required Services (Enable in Firebase Console)
1. **Authentication**:
   - Go to Firebase Console → Authentication → Sign-in method
   - Enable **Email/Password**
   - Enable **Anonymous** (for students)

2. **Firestore Database**:
   - Create database in production or test mode
   - Security rules can be configured later

3. **Cloud Messaging** (Optional for push notifications):
   - Already configured via `google-services.json`

## Gemini API Configuration

1. Get API key from: https://makersuite.google.com/app/apikey
2. Open `lib/services/llm_service.dart`
3. Replace `YOUR_GEMINI_API_KEY_HERE` with your actual key

## Installation

```bash
# 1. Navigate to project
cd "f:\final src\flutter_application"

# 2. Get dependencies
flutter pub get

# 3. Run on device/emulator
flutter run
```

## Android Permissions Setup

### Manual Steps Required by User
1. After installing the app, go to:
   - **Settings → Accessibility → EduGuardian**
   - Enable the accessibility service

2. Grant microphone permission when prompted (for blind mode)

## Testing

### Test Parent Flow
1. Launch app → Select "Parent"
2. Sign up with email/password
3. After login, tap "Add Student"
4. Fill student details, save (note the generated Student ID)
5. Tap the block icon next to student → Select apps to block
6. Tap "Save Policy"

### Test Student Flow
1. Sign out → Select "Student"
2. Enter the Student ID from previous step
3. Login → You should see the dashboard
4. Toggle "Study Mode" ON
5. Exit app and try to open YouTube (should be blocked if you selected it)

### Test Blind Mode
1. Sign out → Select "Student"
2. When voice asks "Are you blind?", say "Yes"
3. App enters voice-only mode
4. Say commands like: "go to assignments", "ai assist", "logout"

### Test AI Chatbot
1. Login as student (normal mode)
2. Go to "AI Assist" tab
3. Type: "What is photosynthesis?"
4. AI should respond (requires valid Gemini API key)

## Troubleshooting

### "App not blocking"
- Ensure Accessibility Service is enabled in Settings
- Check that Study Mode is ON
- Verify blocked apps are saved in policy

### "Voice not working"
- Grant microphone permission
- Check device volume
- Ensure speech_to_text plugin is properly installed

### "Firebase errors"
- Verify `google-services.json` is in `android/app/`
- Check that Firebase services are enabled in console
- Run `flutter clean` and `flutter pub get`

### "Gemini API errors"
- Verify API key is correctly configured
- Check internet connection
- Ensure API key has Gemini API enabled

## Project Structure

```
lib/
├── core/
│   ├── constants.dart
│   └── theme.dart
├── models/
│   ├── user_model.dart
│   ├── student_model.dart
│   ├── parent_model.dart
│   ├── teacher_model.dart
│   ├── assignment_model.dart
│   ├── app_policy_model.dart
│   └── chat_model.dart
├── services/
│   ├── auth_service.dart
│   ├── database_service.dart
│   ├── llm_service.dart
│   ├── voice_service.dart
│   └── study_mode_service.dart
├── features/
│   ├── auth/
│   ├── parent/
│   ├── student/
│   └── teacher/
└── main.dart

android/
└── app/
    └── src/
        └── main/
            ├── kotlin/.../AppMonitoringService.kt
            └── AndroidManifest.xml
```
