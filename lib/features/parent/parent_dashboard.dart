import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../models/student_model.dart';
import 'add_student_screen.dart';
import 'app_blocking_screen.dart';
import 'parent_assignment_screen.dart';
import 'parent_chat_list_screen.dart';
import 'parent_notifications_screen.dart';
import 'live_monitor_screen.dart';
import 'student_history_screen.dart';
import '../../core/theme.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final dbService = Provider.of<DatabaseService>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final parentId = authService.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.purpleGradient),
        ),
        title: const Text(
          'Parent Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _StudentsTab(parentId: parentId),
          ParentAssignmentScreen(parentId: parentId),
          ParentChatListScreen(parentId: parentId),
          ParentNotificationsScreen(parentId: parentId),
        ],
      ),
      bottomNavigationBar: StreamBuilder<int>(
        stream: dbService.getUnreadChatCount(parentId),
        builder: (context, chatSnapshot) {
          final unreadChatCount = chatSnapshot.data ?? 0;

          return StreamBuilder<int>(
            stream: notificationService.getUnreadCount(parentId),
            builder: (context, notifSnapshot) {
              final unreadNotifCount = notifSnapshot.data ?? 0;

              return NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected:
                    (index) => setState(() => _selectedIndex = index),
                destinations: [
                  const NavigationDestination(
                    icon: Icon(Icons.people),
                    label: 'Students',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.assignment),
                    label: 'Assignments',
                  ),
                  NavigationDestination(
                    icon:
                        unreadChatCount > 0
                            ? Badge(
                              label: Text('$unreadChatCount'),
                              child: const Icon(Icons.chat),
                            )
                            : const Icon(Icons.chat),
                    label: 'Chats',
                  ),
                  NavigationDestination(
                    icon:
                        unreadNotifCount > 0
                            ? Badge(
                              label: Text('$unreadNotifCount'),
                              child: const Icon(Icons.notifications),
                            )
                            : const Icon(Icons.notifications),
                    label: 'Alerts',
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton:
          _selectedIndex == 0
              ? FloatingActionButton.extended(
                onPressed:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => AddStudentScreen(parentId: parentId),
                      ),
                    ),
                icon: const Icon(Icons.person_add),
                label: const Text('Add Student'),
                backgroundColor: AppTheme.primaryLight,
              )
              : null,
    );
  }
}

class _StudentsTab extends StatelessWidget {
  final String parentId;
  const _StudentsTab({required this.parentId});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    return FutureBuilder<List<StudentModel>>(
      future: dbService.getParentStudents(parentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people_outline,
                  size: 100,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 24),
                Text(
                  'No students yet',
                  style: TextStyle(fontSize: 20, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to add a student',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final student = snapshot.data![index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryLight.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        student.fullName[0].toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryLight,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      student.fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('Grade ${student.grade} ${student.section}'),
                        if (student.isBlind)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Voice mode',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.block),
                      color: AppTheme.accentOrange,
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => AppBlockingScreen(
                                    studentId: student.studentId,
                                    parentId: parentId,
                                  ),
                            ),
                          ),
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => StudentHistoryScreen(
                                          studentId: student.studentId,
                                        ),
                                  ),
                                ),
                            icon: const Icon(Icons.history),
                            label: const Text('History'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryLight,
                              side: const BorderSide(
                                color: AppTheme.primaryLight,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => LiveMonitorScreen(
                                          studentId: student.studentId,
                                          studentName: student.fullName,
                                        ),
                                  ),
                                ),
                            icon: const Icon(Icons.remove_red_eye),
                            label: const Text('Live View'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentOrange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
