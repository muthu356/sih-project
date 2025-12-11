import 'package:flutter/material.dart';
import '../../services/database_service.dart';

class StudentHistoryScreen extends StatelessWidget {
  final String studentId;
  const StudentHistoryScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(title: const Text("Activity History")),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: db.getUsageHistory(studentId, startOfDay, endOfDay),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data!;
          if (events.isEmpty) {
            return const Center(child: Text("No activity recorded today"));
          }

          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              final duration = Duration(seconds: event['durationSeconds'] ?? 0);

              return ListTile(
                leading: CircleAvatar(child: Text(event['appName'][0])),
                title: Text(event['appName']),
                subtitle: Text(event['title'] ?? ''),
                trailing: Text(
                  "${duration.inMinutes}m ${duration.inSeconds % 60}s",
                ),
              );
            },
          );
        },
      ),
    );
  }
}
