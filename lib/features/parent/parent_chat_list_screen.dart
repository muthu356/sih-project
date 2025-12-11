import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/teacher_model.dart';
import 'parent_teacher_chat_screen.dart';
import '../../core/theme.dart';

class ParentChatListScreen extends StatelessWidget {
  final String parentId;
  const ParentChatListScreen({super.key, required this.parentId});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    return Scaffold(
      body: FutureBuilder<List<StudentModel>>(
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
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No students yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add students to start chatting with teachers',
                    style: TextStyle(color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          final students = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,
            itemBuilder: (context, index) {
              final student = students[index];
              return _StudentChatCard(student: student, parentId: parentId);
            },
          );
        },
      ),
    );
  }
}

class _StudentChatCard extends StatelessWidget {
  final StudentModel student;
  final String parentId;

  const _StudentChatCard({required this.student, required this.parentId});

  @override
  Widget build(BuildContext context) {
    if (student.teacherIds.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryLight.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      student.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Grade ${student.grade} ${student.section}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No teacher assigned yet',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.1),
                  child: Text(
                    student.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Grade ${student.grade} ${student.section}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...student.teacherIds.map(
            (teacherId) => _TeacherChatTile(
              teacherId: teacherId,
              studentId: student.studentId,
              studentName: student.fullName,
              parentId: parentId,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeacherChatTile extends StatelessWidget {
  final String teacherId;
  final String studentId;
  final String studentName;
  final String parentId;

  const _TeacherChatTile({
    required this.teacherId,
    required this.studentId,
    required this.studentName,
    required this.parentId,
  });

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    return FutureBuilder<TeacherModel?>(
      future: dbService.getTeacher(teacherId),
      builder: (context, snapshot) {
        final teacher = snapshot.data;
        final teacherName = teacher?.fullName ?? 'Loading...';

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 20),
          ),
          title: Text(teacherName),
          subtitle: const Text('Tap to chat'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (teacher != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ParentTeacherChatScreen(
                        currentUserId: parentId,
                        currentUserRole: 'parent',
                        parentId: parentId,
                        teacherId: teacherId,
                        studentId: studentId,
                        studentName: studentName,
                      ),
                ),
              );
            }
          },
        );
      },
    );
  }
}
