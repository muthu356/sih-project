import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String studentId;
  final String? userId;
  final String fullName;
  final String grade;
  final String section;
  final String schoolName;
  final List<String> parentIds;
  final List<String> teacherIds;
  final bool isBlind;
  final bool voiceOnlyMode;
  final bool studyModeEnabled;
  final int studyMinutes;
  final DateTime createdAt;

  StudentModel({
    required this.studentId,
    this.userId,
    required this.fullName,
    required this.grade,
    required this.section,
    required this.schoolName,
    this.parentIds = const [],
    this.teacherIds = const [],
    this.isBlind = false,
    this.voiceOnlyMode = false,
    this.studyModeEnabled = false,
    this.studyMinutes = 0,
    required this.createdAt,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentModel(
      studentId: doc.id,
      userId: data['userId'],
      fullName: data['fullName'] ?? '',
      grade: data['grade'] ?? '',
      section: data['section'] ?? '',
      schoolName: data['schoolName'] ?? '',
      parentIds: List<String>.from(data['parentIds'] ?? []),
      teacherIds: List<String>.from(data['teacherIds'] ?? []),
      isBlind: data['isBlind'] ?? false,
      voiceOnlyMode: data['voiceOnlyMode'] ?? false,
      studyModeEnabled: data['studyModeEnabled'] ?? false,
      studyMinutes: data['studyMinutes'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'userId': userId,
      'fullName': fullName,
      'grade': grade,
      'section': section,
      'schoolName': schoolName,
      'parentIds': parentIds,
      'teacherIds': teacherIds,
      'isBlind': isBlind,
      'voiceOnlyMode': voiceOnlyMode,
      'studyModeEnabled': studyModeEnabled,
      'studyMinutes': studyMinutes,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  StudentModel copyWith({
    String? userId,
    String? fullName,
    String? grade,
    String? section,
    String? schoolName,
    List<String>? parentIds,
    List<String>? teacherIds,
    bool? isBlind,
    bool? voiceOnlyMode,
    bool? studyModeEnabled,
    int? studyMinutes,
  }) {
    return StudentModel(
      studentId: studentId,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      schoolName: schoolName ?? this.schoolName,
      parentIds: parentIds ?? this.parentIds,
      teacherIds: teacherIds ?? this.teacherIds,
      isBlind: isBlind ?? this.isBlind,
      voiceOnlyMode: voiceOnlyMode ?? this.voiceOnlyMode,
      studyModeEnabled: studyModeEnabled ?? this.studyModeEnabled,
      studyMinutes: studyMinutes ?? this.studyMinutes,
      createdAt: createdAt,
    );
  }
}
