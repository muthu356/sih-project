import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/assignment_model.dart';

class TeacherAssignmentScreen extends StatelessWidget {
  final String teacherId;
  const TeacherAssignmentScreen({Key? key, required this.teacherId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    return FutureBuilder<List<StudentModel>>(
      future: dbService.getTeacherStudents(teacherId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No students linked yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final student = snapshot.data![index];
            return Card(
              child: ExpansionTile(
                leading: CircleAvatar(child: Text(student.fullName[0])),
                title: Text(student.fullName),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton.icon(
                      onPressed: () => _createAssignment(context, student.studentId, teacherId),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Assignment'),
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

  void _createAssignment(BuildContext context, String studentId, String teacherId) async {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Assignment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final assignment = AssignmentModel(
        assignmentId: '',
        createdByType: 'teacher',
        createdById: teacherId,
        studentId: studentId,
        title: titleController.text,
        description: descController.text,
        createdAt: DateTime.now(),
      );

      await dbService.createAssignment(assignment);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment created!')),
        );
      }
    }
  }
}
