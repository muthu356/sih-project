import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new notification
  Future<void> createNotification(NotificationModel notification) async {
    await _firestore.collection('notifications').add(notification.toFirestore());
  }

  // Send app violation notification to parent
  Future<void> sendAppViolationNotification({
    required String parentId,
    required String studentId,
    required String studentName,
    required String appName,
    required String classification,
  }) async {
    final notification = NotificationModel(
      notificationId: '',
      recipientId: parentId,
      studentId: studentId,
      title: 'Non-Educational App Detected',
      message: '$studentName attempted to use $appName during study mode. AI classified the content as: $classification',
      type: 'app_violation',
      createdAt: DateTime.now(),
      metadata: {
        'appName': appName,
        'classification': classification,
        'studentName': studentName,
      },
    );

    await createNotification(notification);
  }

  // Get notifications for a parent
  Stream<List<NotificationModel>> getParentNotifications(String parentId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: parentId)
        .snapshots()
        .map((snapshot) {
          final notifications = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc.data(), doc.id))
              .toList();
          // Sort in memory instead of using Firestore orderBy
          notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return notifications.take(50).toList();
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  // Get unread count
  Stream<int> getUnreadCount(String parentId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: parentId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Generic method to send notification to any user (for chat notifications)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final notification = NotificationModel(
      notificationId: '',
      recipientId: userId,
      studentId: '',
      title: title,
      message: body,
      type: type,
      createdAt: DateTime.now(),
      metadata: relatedId != null ? {'relatedId': relatedId} : {},
    );

    await _firestore.collection('notifications').add(notification.toFirestore());
  }
}
