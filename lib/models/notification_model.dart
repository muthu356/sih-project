class NotificationModel {
  final String notificationId;
  final String recipientId; // Parent ID
  final String studentId;
  final String title;
  final String message;
  final String type; // 'app_violation', 'study_mode_disabled', 'assignment_submitted'
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic> metadata; // Additional data like app name, content classification

  NotificationModel({
    required this.notificationId,
    required this.recipientId,
    required this.studentId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.metadata = const {},
  });

  factory NotificationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return NotificationModel(
      notificationId: id,
      recipientId: data['recipientId'] ?? '',
      studentId: data['studentId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'recipientId': recipientId,
      'studentId': studentId,
      'title': title,
      'message': message,
      'type': type,
      'createdAt': createdAt,
      'isRead': isRead,
      'metadata': metadata,
    };
  }
}
