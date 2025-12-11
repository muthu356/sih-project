import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/student_model.dart';
import '../../models/assignment_model.dart';
import '../../core/theme.dart';

class StudentProgressScreen extends StatelessWidget {
  final StudentModel student;

  const StudentProgressScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${student.fullName}\'s Progress'),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.purpleGradient),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildStudyStats(),
            const SizedBox(height: 16),
            _buildGradeStats(dbService),
            const SizedBox(height: 16),
            _buildAssignmentStats(dbService),
            const SizedBox(height: 24),
            _buildRecentActivity(dbService),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.1),
              child: Text(
                student.fullName[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryLight,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Grade ${student.grade} ${student.section}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudyStats() {
    final hours = (student.studyMinutes / 60).toStringAsFixed(1);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.timer, color: Colors.blue, size: 30),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$hours Hours',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Total Study Time',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeStats(DatabaseService dbService) {
    return FutureBuilder<List<AssignmentSubmission>>(
      future: dbService.getStudentSubmissions(student.studentId),
      builder: (context, snapshot) {
        String averageGrade = 'N/A';
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final submissions = snapshot.data!;
          final gradedSubmissions =
              submissions.where((s) => s.grade != null).toList();

          if (gradedSubmissions.isNotEmpty) {
            // Assuming grades are numeric strings like "90", "85".
            // If they are letters, this logic would need to be different.
            // For now, we'll try to parse them, or just show the latest one.
            double total = 0;
            int count = 0;
            for (var s in gradedSubmissions) {
              final grade = double.tryParse(s.grade!);
              if (grade != null) {
                total += grade;
                count++;
              }
            }
            if (count > 0) {
              averageGrade = '${(total / count).toStringAsFixed(1)}%';
            }
          }
        }

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.grade, color: Colors.green, size: 30),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      averageGrade,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Average Grade',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAssignmentStats(DatabaseService dbService) {
    return StreamBuilder<List<AssignmentModel>>(
      stream: dbService.getStudentAssignments(student.studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No assignments found');
        }

        final assignments = snapshot.data!;
        final total = assignments.length;
        final completed =
            assignments
                .where((a) => a.status == AssignmentStatus.completed)
                .length;
        final progress = total == 0 ? 0.0 : completed / total;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assignment Completion',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$completed / $total Completed',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade100,
                    color: AppTheme.primaryLight,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity(DatabaseService dbService) {
    // For now, we reuse the assignments stream to show recent ones
    return StreamBuilder<List<AssignmentModel>>(
      stream: dbService.getStudentAssignments(student.studentId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final recentAssignments = snapshot.data!.take(5).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Assignments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentAssignments.length,
              itemBuilder: (context, index) {
                final assignment = recentAssignments[index];
                final isCompleted =
                    assignment.status == AssignmentStatus.completed;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          isCompleted
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                      child: Icon(
                        isCompleted ? Icons.check : Icons.pending_actions,
                        color: isCompleted ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      assignment.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      assignment.dueDate != null
                          ? 'Due: ${_formatDate(assignment.dueDate!)}'
                          : 'No due date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing:
                        isCompleted
                            ? const Text(
                              'Done',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                            : const Text(
                              'Pending',
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey.shade500)),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
