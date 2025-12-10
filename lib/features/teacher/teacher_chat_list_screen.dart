import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/parent_model.dart';
import '../parent/parent_teacher_chat_screen.dart';
import '../../core/theme.dart';

class TeacherChatListScreen extends StatelessWidget {
  final String teacherId;
  const TeacherChatListScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    return Scaffold(
      body: FutureBuilder<List<StudentModel>>(
        future: dbService.getTeacherStudents(teacherId),
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
                    'Link to students to start chatting with parents',
                    style: TextStyle(color: Colors.grey.shade400),
                    textAlign: TextAlign.center,
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
              return _StudentParentCard(student: student, teacherId: teacherId);
            },
          );
        },
      ),
    );
  }
}

class _StudentParentCard extends StatelessWidget {
  final StudentModel student;
  final String teacherId;

  const _StudentParentCard({required this.student, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    if (student.parentIds.isEmpty) {
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
                    backgroundColor: AppTheme.accentOrange.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      student.fullName[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.accentOrange,
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
                        'No parent assigned yet',
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
                  backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.1),
                  child: Text(
                    student.fullName[0].toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.accentOrange,
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
          ...student.parentIds.map(
            (parentId) => _ParentChatTile(
              parentId: parentId,
              studentId: student.studentId,
              studentName: student.fullName,
              teacherId: teacherId,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParentChatTile extends StatelessWidget {
  final String parentId;
  final String studentId;
  final String studentName;
  final String teacherId;

  const _ParentChatTile({
    required this.parentId,
    required this.studentId,
    required this.studentName,
    required this.teacherId,
  });

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    return FutureBuilder<ParentModel?>(
      future: dbService.getParent(parentId),
      builder: (context, snapshot) {
        final parent = snapshot.data;
        final parentName = parent?.fullName ?? 'Loading...';

        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppTheme.purpleGradient,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.family_restroom,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(parentName),
          subtitle: Text('Parent of $studentName'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (parent != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ParentTeacherChatScreen(
                        currentUserId: teacherId,
                        currentUserRole: 'teacher',
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
