import 'package:cloud_firestore/cloud_firestore.dart';

class BlockedApp {
  final String packageName;
  final String appName;
  final String? blockedReason;

  BlockedApp({
    required this.packageName,
    required this.appName,
    this.blockedReason,
  });

  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'appName': appName,
      'blockedReason': blockedReason,
    };
  }

  factory BlockedApp.fromMap(Map<String, dynamic> map) {
    return BlockedApp(
      packageName: map['packageName'] ?? '',
      appName: map['appName'] ?? '',
      blockedReason: map['blockedReason'],
    );
  }
}

class AppPolicyModel {
  final String policyId;
  final String studentId;
  final String parentId;
  final List<BlockedApp> blockedApps;
  final DateTime updatedAt;

  AppPolicyModel({
    required this.policyId,
    required this.studentId,
    required this.parentId,
    this.blockedApps = const [],
    required this.updatedAt,
  });

  factory AppPolicyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final blockedAppsList = (data['blockedApps'] as List?)?.map((item) {
      return BlockedApp.fromMap(item as Map<String, dynamic>);
    }).toList() ?? [];

    return AppPolicyModel(
      policyId: doc.id,
      studentId: data['studentId'] ?? '',
      parentId: data['parentId'] ?? '',
      blockedApps: blockedAppsList,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'parentId': parentId,
      'blockedApps': blockedApps.map((app) => app.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Get comma-separated package names for SharedPreferences
  String getBlockedPackagesString() {
    return blockedApps.map((app) => app.packageName).join(',');
  }
}
