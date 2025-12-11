import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/theme.dart';
import 'models/user_model.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/auth/parent_login_screen.dart';
import 'features/auth/teacher_login_screen.dart';
import 'features/auth/student_login_screen.dart';
import 'features/parent/parent_dashboard.dart';
import 'features/teacher/teacher_dashboard.dart';

import 'features/student/student_dashboard_entry.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<NotificationService>(create: (_) => NotificationService()),
      ],
      child: MaterialApp(
        title: 'EduGuardian',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: {
          '/parent-login': (context) => const ParentLoginScreen(),
          '/teacher-login': (context) => const TeacherLoginScreen(),
          '/student-login': (context) => const StudentLoginScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          // User is logged in - Navigate based on role
          return FutureBuilder<UserModel?>(
            future: authService.getCurrentUserModel(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData) {
                final user = userSnapshot.data!;

                // Return appropriate dashboard based on role
                switch (user.role) {
                  case UserRole.parent:
                    return const ParentDashboard();
                  case UserRole.teacher:
                    return const TeacherDashboard();
                  case UserRole.student:
                    return StudentDashboardEntry(studentId: user.uid);
                }
              }

              // If no user data, go to role selection
              return const RoleSelectionScreen();
            },
          );
        }

        // User is not logged in
        return const RoleSelectionScreen();
      },
    );
  }
}
