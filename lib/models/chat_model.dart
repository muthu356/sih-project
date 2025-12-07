import 'package:cloud_firestore/cloud_firestore.dart';

class ChatThread {
  final String threadId;
  final String studentId;
  final String parentId;
  final String teacherId;
  final String lastMessageText;
  final DateTime lastMessageAt;
  final String lastMessageSenderId;

  ChatThread({
    required this.threadId,
    required this.studentId,
    required this.parentId,
    required this.teacherId,
    this.lastMessageText = '',
    required this.lastMessageAt,
    required this.lastMessageSenderId,
  });

  factory ChatThread.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatThread(
      threadId: doc.id,
      studentId: data['studentId'] ?? '',
      parentId: data['parentId'] ?? '',
      teacherId: data['teacherId'] ?? '',
      lastMessageText: data['lastMessageText'] ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessageSenderId: data['lastMessageSenderId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'parentId': parentId,
      'teacherId': teacherId,
      'participants': [parentId, teacherId],
      'lastMessageText': lastMessageText,
      'lastMessageAt': Timestamp.fromDate(lastMessageAt),
      'lastMessageSenderId': lastMessageSenderId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class ChatMessage {
  final String messageId;
  final String senderId;
  final String senderRole;
  final String text;
  final DateTime createdAt;
  final List<String> seenBy;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.senderRole,
    required this.text,
    required this.createdAt,
    this.seenBy = const [],
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      messageId: doc.id,
      senderId: data['senderId'] ?? '',
      senderRole: data['senderRole'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      seenBy: List<String>.from(data['seenBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderRole': senderRole,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'seenBy': seenBy,
    };
  }
}
