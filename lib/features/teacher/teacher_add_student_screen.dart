import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';

class TeacherAddStudentScreen extends StatefulWidget {
  final String teacherId;
  const TeacherAddStudentScreen({super.key, required this.teacherId});

  @override
  State<TeacherAddStudentScreen> createState() => _TeacherAddStudentScreenState();
}

class _TeacherAddStudentScreenState extends State<TeacherAddStudentScreen> {
  final _studentIdController = TextEditingController();
  bool _isLoading = false;

  Future<void> _linkStudent() async {
    if (_studentIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a student ID')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final studentId = _studentIdController.text.trim();

      // Check if student exists
      final student = await dbService.getStudent(studentId);
      
      if (student == null) {
        throw Exception('Student ID not found. Only parents can create students.');
      }

      await dbService.linkStudentToTeacher(studentId, widget.teacherId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Student linked successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Link Student')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Link Existing Student',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Teachers can only link to students that have been registered by parents.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _studentIdController,
              decoration: InputDecoration(
                labelText: 'Student ID',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'e.g., STU_ABCD1234',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _linkStudent,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: const Text('Link Student'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }
}
