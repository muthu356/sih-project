import 'package:flutter/material.dart';

class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color baseColor;

  const FeatureCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.onTap,
    required this.baseColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: baseColor.withOpacity(0.15),
              offset: const Offset(8, 8),
              blurRadius: 16,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.white,
              offset: const Offset(-4, -4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              baseColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: baseColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: baseColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
