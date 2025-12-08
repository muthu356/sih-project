import 'package:flutter/material.dart';
import '../widgets/feature_card.dart';
import '../../presentation/pages/work_assign_page.dart';
import '../../presentation/pages/students_manage_page.dart';
import '../../presentation/pages/parent_connect_page.dart';
import '../../presentation/pages/tp_chat_page.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // School-friendly color palette
    final Color primaryColor = const Color(0xFF6C63FF); // Purple
    final Color secondaryColor = const Color(0xFF4FC3F7); // Sky Blue
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey-white background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 80,
        title: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage('https://i.pravatar.cc/300?img=12'), // Placeholder
              backgroundColor: Colors.grey[200],
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, Sarah!',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Class Teacher - 12A',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.grey[800]),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  FeatureCard(
                    title: 'Assign Work',
                    icon: Icons.assignment_outlined,
                    baseColor: primaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const WorkAssignPage()),
                    ),
                  ),
                  FeatureCard(
                    title: 'Manage Students',
                    icon: Icons.people_outline,
                    baseColor: secondaryColor,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentsManagePage()),
                    ),
                  ),
                  FeatureCard(
                    title: 'Parent Connect',
                    icon: Icons.contact_phone_outlined,
                    baseColor: Colors.orangeAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ParentConnectPage()),
                    ),
                  ),
                  FeatureCard(
                    title: 'Chat Support',
                    icon: Icons.chat_bubble_outline,
                    baseColor: Colors.pinkAccent,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TPChatPage()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TPChatPage()),
        ),
        backgroundColor: primaryColor,
        child: const Icon(Icons.message, color: Colors.white),
      ),
    );
  }
}
