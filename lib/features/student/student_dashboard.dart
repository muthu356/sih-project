import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/study_mode_service.dart';
import '../../models/student_model.dart';
import '../../models/app_policy_model.dart';
import 'student_assignment_screen.dart';
import 'student_ai_assist_screen.dart';
import '../../core/theme.dart';

class StudentDashboard extends StatefulWidget {
  final String studentId;
  const StudentDashboard({Key? key, required this.studentId}) : super(key: key);

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        title: const Text('Student Dashboard', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = Provider.of<AuthService>(context, listen: false);
              await authService.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(
            studentId: widget.studentId,
            onTabChanged: (index) => setState(() => _selectedIndex = index),
          ),
          StudentAssignmentScreen(studentId: widget.studentId),
          StudentAIAssistScreen(studentId: widget.studentId),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.assignment), label: 'Assignments'),
          NavigationDestination(icon: Icon(Icons.psychology), label: 'AI Assist'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  final String studentId;
  final Function(int) onTabChanged;
  
  const _HomeTab({
    required this.studentId,
    required this.onTabChanged,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final StudyModeService _studyModeService = StudyModeService();
  bool _isStudyMode = false;

  @override
  void initState() {
    super.initState();
    _loadStudyMode();
  }

  Future<void> _loadStudyMode() async {
    final enabled = await _studyModeService.isStudyModeEnabled();
    setState(() => _isStudyMode = enabled);
  }

  Future<void> _toggleStudyMode(bool value, StudentModel student) async {
    setState(() => _isStudyMode = value);

    if (value) {
      await _studyModeService.enableStudyMode();
      
      if (student.parentIds.isNotEmpty) {
        final dbService = Provider.of<DatabaseService>(context, listen: false);
        final policy = await dbService.getAppPolicy(widget.studentId, student.parentIds.first);
        
        if (policy != null) {
          final blockedPackages = policy.blockedApps.join(',');
          await _studyModeService.updateBlockedApps(blockedPackages);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Study mode enabled - Blocked apps will not open'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await _studyModeService.disableStudyMode();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study mode disabled')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);

    return StreamBuilder<StudentModel?>(
      stream: dbService.studentStream(widget.studentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('Student not found'));
        }

        final student = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Gradient
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundColor: Colors.white,
                          child: Text(
                            student.fullName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 32,
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
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Grade ${student.grade} ${student.section}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Study Mode Card
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _isStudyMode ? AppTheme.accentGradient : null,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.school,
                                  size: 40,
                                  color: _isStudyMode ? Colors.white : AppTheme.primaryLight,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Study Mode',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: _isStudyMode ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        _isStudyMode ? 'Apps are blocked' : 'Enable to focus',
                                        style: TextStyle(
                                          color: _isStudyMode ? Colors.white70 : Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _isStudyMode,
                                  onChanged: (value) => _toggleStudyMode(value, student),
                                  activeColor: Colors.white,
                                  activeTrackColor: Colors.white38,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Quick Actions',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    // Quick Action Cards
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.assignment,
                            title: 'Assignments',
                            color: AppTheme.primaryLight,
                            onTap: () => widget.onTabChanged(1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.psychology,
                            title: 'AI Tutor',
                            color: AppTheme.accentOrange,
                            onTap: () => widget.onTabChanged(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
