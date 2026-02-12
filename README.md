# 📚 Smart Student Monitoring & Learning Assistant

> A comprehensive Flutter-based educational platform developed for **Smart India Hackathon (SIH)** that enables parents and teachers to monitor student learning, manage assignments, and provide AI-powered assistance.

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-83.5%25-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-red)]()

## 🌟 Overview

This cross-platform mobile application provides a comprehensive ecosystem for monitoring and enhancing student learning experiences. It connects **parents**, **teachers**, and **students** in a unified platform with features ranging from app blocking during study sessions to AI-powered learning assistance and accessibility features for visually impaired students.

---

## ✨ Key Features

### 👨‍👩‍👧 For Parents
- **📱 Real-time Student Monitoring**
  - Track active study sessions in real-time
  - Monitor app usage and screen time
  - Receive instant alerts for distracting activities

- **🚫 Smart App Blocking**
  - Configure blocked apps per student
  - Custom whitelists for study mode
  - Educational vs non-educational app classification using AI

- **📝 Assignment Management**
  - Create and assign homework to students
  - Track submission status and progress
  - Review completed assignments

- **💬 Teacher Communication**
  - Direct chat with teachers about student progress
  - Dedicated chat threads per student
  - Real-time messaging with notifications

- **👥 Multi-Student Management**
  - Manage multiple children from one account
  - Individual profiles with custom settings
  - Per-child app blocking policies

### 🎓 For Students
- **📖 Study Mode**
  - One-tap study mode activation
  - Automatic app blocking based on parent/teacher policies
  - Focus time tracking and analytics

- **📚 Assignment Hub**
  - View all assigned tasks from parents and teachers
  - Submit assignments with text and attachments
  - Track deadlines and completion status

- **🤖 AI Learning Assistant**
  - Powered by **Google Generative AI (Gemini)**
  - Ask doubts and get instant explanations
  - Context-aware educational support
  - Subject-specific help

- **♿ Accessibility Features (Blind Mode)**
  - **Voice-controlled interface** using Speech-to-Text
  - **Text-to-Speech** for content reading
  - Fully hands-free navigation
  - Screen reader optimized UI

- **📊 Progress Tracking**
  - View study session history
  - Analyze focus time vs distraction events
  - Performance insights

### 👨‍🏫 For Teachers
- **👥 Student Management**
  - Link existing students to your account
  - View all assigned students
  - Track student-teacher relationships

- **📋 Assignment Creation**
  - Create assignments for individual students
  - Set due dates and descriptions
  - Attach files and resources

- **💬 Parent Communication**
  - Chat with parents about student performance
  - Share progress updates
  - Collaborative monitoring

- **📈 Student Analytics**
  - Monitor student engagement
  - Track assignment completion rates
  - Identify struggling students

---

## 🛠️ Technology Stack

### Frontend
- **Framework**: Flutter 3.7.2+
- **Language**: Dart (83.5%)
- **State Management**: Provider
- **UI Components**: Material Design with Google Fonts

### Backend & Services
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **AI Integration**: Google Generative AI (Gemini API)

### Core Dependencies
| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialization |
| `firebase_auth` | User authentication |
| `cloud_firestore` | Real-time database |
| `firebase_messaging` | Push notifications |
| `google_generative_ai` | AI chatbot integration |
| `provider` | State management |
| `speech_to_text` | Voice input (accessibility) |
| `flutter_tts` | Text-to-speech (accessibility) |
| `app_usage` | Monitor app usage on device |
| `permission_handler` | Request device permissions |
| `google_fonts` | Custom typography |

### Platform Support
✅ Android  
✅ iOS  
✅ Web  
✅ Windows  
✅ macOS  
✅ Linux

---

## 🏗️ Architecture

### Database Schema

#### Core Collections
```
/users                    → Common auth identity (uid, role, email)
/parents                  → Parent-specific data
/students                 → Student profiles (including blind students)
/teachers                 → Teacher profiles
/parent_student_links     → Parent-child relationships
/teacher_student_links    → Teacher-student assignments
/assignments              → Homework/tasks
/assignment_submissions   → Student submissions
/chat_threads             → Parent-teacher communication
/study_sessions           → Study mode tracking
  └─ /events              → App usage events during sessions
/app_policies             → App blocking rules per student
/notifications            → FCM tokens and notification logs
```

#### Key Relationships
- **Many-to-Many**: Parents ↔ Students (via `parent_student_links`)
- **Many-to-Many**: Teachers ↔ Students (via `teacher_student_links`)
- **One-to-Many**: Students → Assignments, Study Sessions
- **One-to-One**: Parent + Teacher → Chat Thread (per student)

### App Architecture
```
lib/
├── main.dart                          # App entry point
├── screens/
│   ├── auth/                          # Login/Registration screens
│   ├── parent/
│   │   ├── parent_dashboard.dart      # Main parent dashboard
│   │   ├── add_student_screen.dart    # Register new student
│   │   ├── app_blocking_screen.dart   # Configure blocked apps
│   │   ├── parent_assignment_screen.dart
│   │   └── parent_chat_screen.dart
│   ├── student/
│   │   ├── student_dashboard.dart     # Main student dashboard
│   │   ├── student_assignment_screen.dart
│   │   ├── student_ai_assist_screen.dart  # AI chatbot
│   │   └── student_blind_mode.dart    # Voice-controlled UI
│   └── teacher/
│       ├── teacher_dashboard.dart
│       ├── teacher_add_student_screen.dart
│       ├── teacher_assignment_screen.dart
│       └── teacher_chat_screen.dart
├── services/
│   ├── auth_service.dart              # Firebase Auth wrapper
│   ├── firestore_service.dart         # Database operations
│   └── llm_service.dart               # AI classification/chatbot
├── models/                            # Data models
├── providers/                         # State management
└── widgets/
    └── chat_widget.dart               # Reusable chat interface
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: 3.7.2 or higher
- **Dart SDK**: Included with Flutter
- **Firebase Account**: With Firestore, Auth, and Cloud Messaging enabled
- **Android Studio** / **Xcode** (for mobile development)
- **Git**

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/muthu356/sih-project.git
   cd sih-project
   git checkout dev-mallikarjuna
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a new Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable **Authentication**, **Firestore Database**, and **Cloud Messaging**
   - Download configuration files:
     - **Android**: `google-services.json` → `android/app/`
     - **iOS**: `GoogleService-Info.plist` → `ios/Runner/`
     - **Web**: Add Firebase config to `web/index.html`

4. **Configure Gemini AI**
   - Get API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Add to your environment or configuration file

5. **Permissions Setup**
   
   **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.RECORD_AUDIO"/>
   <uses-permission android:name="android.permission.PACKAGE_USAGE_STATS"/>
   <uses-permission android:name="android.permission.BIND_ACCESSIBILITY_SERVICE"/>
   ```

   **iOS** (`ios/Runner/Info.plist`):
   ```xml
   <key>NSMicrophoneUsageDescription</key>
   <string>We need microphone access for voice input in blind mode</string>
   <key>NSSpeechRecognitionUsageDescription</key>
   <string>We need speech recognition for voice commands</string>
   ```

### Running the App

```bash
# Run on connected device/emulator
flutter run

# Build for specific platforms
flutter build apk          # Android APK
flutter build ios          # iOS
flutter build web          # Web
flutter build windows      # Windows
```

---

## 📖 Usage Guide

### User Roles & Workflows

#### 1️⃣ Parent Workflow
1. **Register** → Select "Parent" role
2. **Add Student** → Register child with school details
3. **Configure App Blocking** → Set blocked apps for study mode
4. **Create Assignments** → Assign homework to child
5. **Monitor Real-time** → Watch active study sessions
6. **Chat with Teachers** → Discuss child's progress

#### 2️⃣ Student Workflow
1. **Login** → Use credentials provided by parent
2. **Enable Study Mode** → Blocks distracting apps
3. **Complete Assignments** → Submit work with attachments
4. **Use AI Assistant** → Get help with doubts
5. **Blind Mode** (if enabled) → Voice-controlled navigation

#### 3️⃣ Teacher Workflow
1. **Register** → Select "Teacher" role
2. **Link Students** → Connect with existing student IDs
3. **Create Assignments** → Assign tasks to students
4. **Monitor Progress** → Track submissions
5. **Communicate with Parents** → Share insights via chat

---

## 🔐 Security & Privacy

- **Authentication**: Firebase Auth with secure token management
- **Data Isolation**: Firestore security rules enforce role-based access
- **Encrypted Storage**: Sensitive data stored securely
- **Permission-based**: Explicit user consent required for usage tracking
- **No Unauthorized Linking**: Teachers cannot create students, only link existing ones

### Firestore Security Rules Example
```javascript
match /students/{studentId} {
  allow read: if isParentOf(studentId) || isTeacherOf(studentId) || isStudent(studentId);
  allow write: if isParentOf(studentId);
}
```

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Integration tests
flutter drive --target=test_driver/app.dart
```

---

## 🎨 Screenshots

> *Add screenshots of parent dashboard, student study mode, AI assistant, and blind mode interface*

---

## 📋 Roadmap

- [ ] **v1.1**: Offline mode with local caching
- [ ] **v1.2**: Advanced analytics dashboard with charts
- [ ] **v1.3**: Multi-language support (Hindi, Tamil, etc.)
- [ ] **v2.0**: Gamification (badges, streaks, leaderboards)
- [ ] **v2.1**: Video call integration for parent-teacher meetings
- [ ] **v2.2**: ML-based personalized study recommendations

---

## 🤝 Contributing

This is a private project for Smart India Hackathon. If you're a team member:

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Commit changes: `git commit -m "Add your feature"`
3. Push to branch: `git push origin feature/your-feature`
4. Create Pull Request to `dev-mallikarjuna`

---

## 👥 Team

**Development Branch**: `dev-mallikarjuna`  
**Contributors**: 2

---

## 📄 License

This project is private and proprietary. Developed for Smart India Hackathon 2025.

---

## 📞 Support

For issues or questions:
- Create an issue in the repository
- Contact team lead: [Insert contact details]

---

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Firebase** for backend infrastructure
- **Google AI** for Gemini integration
- **Smart India Hackathon** organizers

---

<div align="center">

**Built with ❤️ for Smart India Hackathon 2025**

[⬆ Back to Top](#-smart-student-monitoring--learning-assistant)

</div>
