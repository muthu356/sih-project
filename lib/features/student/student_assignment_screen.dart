import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/assignment_model.dart';

class StudentAssignmentScreen extends StatelessWidget {
  final String studentId;
  const StudentAssignmentScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    return StreamBuilder<List<AssignmentModel>>(
      stream: dbService.getStudentAssignments(studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text('No assignments yet'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final assignment = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(assignment.status),
                  child: const Icon(Icons.assignment, color: Colors.white),
                ),
                title: Text(assignment.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(assignment.description),
                    const SizedBox(height: 4),
                    Text(
                      'From: ${assignment.createdByType}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (assignment.dueDate != null)
                      Text(
                        'Due: ${assignment.dueDate.toString().substring(0, 10)}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: assignment.status == AssignmentStatus.completed
                      ? null
                      : () => _submitAssignment(context, assignment),
                  child: Text(assignment.status == AssignmentStatus.completed ? 'Done' : 'Submit'),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.completed:
        return Colors.green;
      case AssignmentStatus.inProgress:
        return Colors.orange;
      case AssignmentStatus.overdue:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _submitAssignment(BuildContext context, AssignmentModel assignment) async {
    final contentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Assignment'),
        content: TextField(
          controller: contentController,
          decoration: const InputDecoration(
            labelText: 'Your Answer',
            hintText: 'Enter your submission here...',
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final submission = AssignmentSubmission(
        submissionId: '',
        assignmentId: assignment.assignmentId,
        studentId: studentId,
        content: contentController.text,
        submittedAt: DateTime.now(),
      );

      await dbService.submitAssignment(submission);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Assignment submitted!')),
        );
      }
    }
  }
}
