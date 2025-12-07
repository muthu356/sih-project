import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentStatus { assigned, inProgress, completed, overdue }

class AssignmentModel {
  final String assignmentId;
  final String createdByType; // 'parent' or 'teacher'
  final String createdById;
  final String studentId;
  final String title;
  final String description;
  final List<String> attachmentUrls;
  final DateTime? dueDate;
  final AssignmentStatus status;
  final DateTime createdAt;

  AssignmentModel({
    required this.assignmentId,
    required this.createdByType,
    required this.createdById,
    required this.studentId,
    required this.title,
    required this.description,
    this.attachmentUrls = const [],
    this.dueDate,
    this.status = AssignmentStatus.assigned,
    required this.createdAt,
  });

  factory AssignmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssignmentModel(
      assignmentId: doc.id,
      createdByType: data['createdByType'] ?? 'teacher',
      createdById: data['createdById'] ?? '',
      studentId: data['studentId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      attachmentUrls: List<String>.from(data['attachments'] ?? []),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      status: AssignmentStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => AssignmentStatus.assigned,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdByType': createdByType,
      'createdById': createdById,
      'studentId': studentId,
      'title': title,
      'description': description,
      'attachments': attachmentUrls,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class AssignmentSubmission {
  final String submissionId;
  final String assignmentId;
  final String studentId;
  final String content;
  final List<String> attachmentUrls;
  final DateTime submittedAt;
  final String? reviewNotes;
  final String? grade;

  AssignmentSubmission({
    required this.submissionId,
    required this.assignmentId,
    required this.studentId,
    required this.content,
    this.attachmentUrls = const [],
    required this.submittedAt,
    this.reviewNotes,
    this.grade,
  });

  factory AssignmentSubmission.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AssignmentSubmission(
      submissionId: doc.id,
      assignmentId: data['assignmentId'] ?? '',
      studentId: data['studentId'] ?? '',
      content: data['content'] ?? '',
      attachmentUrls: List<String>.from(data['attachments'] ?? []),
      submittedAt: (data['submittedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reviewNotes: data['reviewNotes'],
      grade: data['grade'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'assignmentId': assignmentId,
      'studentId': studentId,
      'content': content,
      'attachments': attachmentUrls,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'reviewNotes': reviewNotes,
      'grade': grade,
    };
  }
}
