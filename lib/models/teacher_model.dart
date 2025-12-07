import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherModel {
  final String teacherId;
  final String userId;
  final String fullName;
  final String email;
  final String phone;
  final List<String> subjects;
  final String schoolName;
  final List<String> assignedStudentIds;
  final DateTime createdAt;

  TeacherModel({
    required this.teacherId,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.subjects = const [],
    required this.schoolName,
    this.assignedStudentIds = const [],
    required this.createdAt,
  });

  factory TeacherModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeacherModel(
      teacherId: doc.id,
      userId: data['userId'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      subjects: List<String>.from(data['subjects'] ?? []),
      schoolName: data['schoolName'] ?? '',
      assignedStudentIds: List<String>.from(data['assignedStudentIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'subjects': subjects,
      'schoolName': schoolName,
      'assignedStudentIds': assignedStudentIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
