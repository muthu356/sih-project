import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'services/auth_service.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';
import 'features/auth/role_selection_screen.dart';
import 'features/auth/parent_login_screen.dart';
import 'features/auth/teacher_login_screen.dart';
import 'features/auth/student_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
  const AuthWrapper({Key? key}) : super(key: key);

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
          return FutureBuilder(
            future: authService.getCurrentUserModel(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userSnapshot.hasData) {
                final user = userSnapshot.data!;
                
                // Navigate to appropriate dashboard based on role
                // Note: This is handled by login screens, so we just show loading
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
