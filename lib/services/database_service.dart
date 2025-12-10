import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import '../models/parent_model.dart';
import '../models/teacher_model.dart';
import '../models/assignment_model.dart';
import '../models/app_policy_model.dart';
import '../models/chat_model.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ========== STUDENTS ==========
  Future<void> createStudent(StudentModel student) async {
    await _firestore
        .collection('students')
        .doc(student.studentId)
        .set(student.toFirestore());
  }

  Future<StudentModel?> getStudent(String studentId) async {
    final doc = await _firestore.collection('students').doc(studentId).get();
    if (!doc.exists) return null;
    return StudentModel.fromFirestore(doc);
  }

  Future<void> updateStudent(
    String studentId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('students').doc(studentId).update(data);
  }

  Stream<StudentModel?> studentStream(String studentId) {
    return _firestore.collection('students').doc(studentId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return StudentModel.fromFirestore(doc);
    });
  }

  // ========== PARENTS ==========
  Future<void> createParent(ParentModel parent) async {
    await _firestore
        .collection('parents')
        .doc(parent.parentId)
        .set(parent.toFirestore());
  }

  Future<ParentModel?> getParent(String parentId) async {
    final doc = await _firestore.collection('parents').doc(parentId).get();
    if (!doc.exists) return null;
    return ParentModel.fromFirestore(doc);
  }

  Future<List<StudentModel>> getParentStudents(String parentId) async {
    final querySnapshot =
        await _firestore
            .collection('students')
            .where('parentIds', arrayContains: parentId)
            .get();
    return querySnapshot.docs
        .map((doc) => StudentModel.fromFirestore(doc))
        .toList();
  }

  // ========== TEACHERS ==========
  Future<void> createTeacher(TeacherModel teacher) async {
    await _firestore
        .collection('teachers')
        .doc(teacher.teacherId)
        .set(teacher.toFirestore());
  }

  Future<TeacherModel?> getTeacher(String teacherId) async {
    final doc = await _firestore.collection('teachers').doc(teacherId).get();
    if (!doc.exists) return null;
    return TeacherModel.fromFirestore(doc);
  }

  Future<List<StudentModel>> getTeacherStudents(String teacherId) async {
    final querySnapshot =
        await _firestore
            .collection('students')
            .where('teacherIds', arrayContains: teacherId)
            .get();
    return querySnapshot.docs
        .map((doc) => StudentModel.fromFirestore(doc))
        .toList();
  }

  // ========== ASSIGNMENTS ==========
  Future<String> createAssignment(AssignmentModel assignment) async {
    final docRef = await _firestore
        .collection('assignments')
        .add(assignment.toFirestore());
    return docRef.id;
  }

  Stream<List<AssignmentModel>> getStudentAssignments(String studentId) {
    return _firestore
        .collection('assignments')
        .where('studentId', isEqualTo: studentId)
        // .orderBy('createdAt', descending: true) // Temporarily removed to debug index issue
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => AssignmentModel.fromFirestore(doc))
                  .toList(),
        );
  }

  Future<void> submitAssignment(AssignmentSubmission submission) async {
    await _firestore
        .collection('assignment_submissions')
        .add(submission.toFirestore());

    // Update assignment status
    await _firestore
        .collection('assignments')
        .doc(submission.assignmentId)
        .update({'status': AssignmentStatus.completed.name});
  }

  Future<List<AssignmentSubmission>> getStudentSubmissions(
    String studentId,
  ) async {
    final querySnapshot =
        await _firestore
            .collection('assignment_submissions')
            .where('studentId', isEqualTo: studentId)
            .get();
    return querySnapshot.docs
        .map((doc) => AssignmentSubmission.fromFirestore(doc))
        .toList();
  }

  // ========== APP POLICIES ==========
  Future<void> saveAppPolicy(AppPolicyModel policy) async {
    await _firestore
        .collection('app_policies')
        .doc(policy.policyId)
        .set(policy.toFirestore());
  }

  Future<AppPolicyModel?> getAppPolicy(
    String studentId,
    String parentId,
  ) async {
    final policyId = '${studentId}_$parentId';
    final doc = await _firestore.collection('app_policies').doc(policyId).get();
    if (!doc.exists) return null;
    return AppPolicyModel.fromFirestore(doc);
  }

  Stream<AppPolicyModel?> appPolicyStream(String studentId, String parentId) {
    final policyId = '${studentId}_$parentId';
    return _firestore.collection('app_policies').doc(policyId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return AppPolicyModel.fromFirestore(doc);
    });
  }

  // ========== CHAT ==========
  Future<String> createChatThread(ChatThread thread) async {
    final docRef = await _firestore
        .collection('chat_threads')
        .add(thread.toFirestore());
    return docRef.id;
  }

  Future<ChatThread?> getChatThread(
    String parentId,
    String teacherId,
    String studentId,
  ) async {
    final querySnapshot =
        await _firestore
            .collection('chat_threads')
            .where('parentId', isEqualTo: parentId)
            .where('teacherId', isEqualTo: teacherId)
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get();

    if (querySnapshot.docs.isEmpty) return null;
    return ChatThread.fromFirestore(querySnapshot.docs.first);
  }

  Stream<List<ChatMessage>> getChatMessages(String threadId) {
    return _firestore
        .collection('chat_threads')
        .doc(threadId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatMessage.fromFirestore(doc))
                  .toList(),
        );
  }

  Future<void> sendMessage(String threadId, ChatMessage message) async {
    await _firestore
        .collection('chat_threads')
        .doc(threadId)
        .collection('messages')
        .add(message.toFirestore());

    // Update thread last message
    await _firestore.collection('chat_threads').doc(threadId).update({
      'lastMessageText': message.text,
      'lastMessageAt': Timestamp.fromDate(message.createdAt),
      'lastMessageSenderId': message.senderId,
    });
  }

  // ========== LINKS ==========
  Future<void> linkStudentToParent(String studentId, String parentId) async {
    // Update student's parentIds
    await _firestore.collection('students').doc(studentId).update({
      'parentIds': FieldValue.arrayUnion([parentId]),
    });

    // Update parent's childrenIds
    await _firestore.collection('parents').doc(parentId).update({
      'childrenIds': FieldValue.arrayUnion([studentId]),
    });

    // Create link document
    await _firestore.collection('parent_student_links').add({
      'parentId': parentId,
      'studentId': studentId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });
  }

  Future<void> linkStudentToTeacher(String studentId, String teacherId) async {
    // Update student's teacherIds
    await _firestore.collection('students').doc(studentId).update({
      'teacherIds': FieldValue.arrayUnion([teacherId]),
    });

    // Update teacher's assignedStudentIds
    await _firestore.collection('teachers').doc(teacherId).update({
      'assignedStudentIds': FieldValue.arrayUnion([studentId]),
    });

    // Create link document
    await _firestore.collection('teacher_student_links').add({
      'teacherId': teacherId,
      'studentId': studentId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
    });
  }

  // ========== CHAT UNREAD COUNTS ==========

  /// Get unread message count for a user (parent or teacher)
  Stream<int> getUnreadChatCount(String userId) {
    return _firestore
        .collection('chat_threads')
        .where('lastMessageSenderId', isNotEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot) async {
          int unreadCount = 0;
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final parentId = data['parentId'] as String?;
            final teacherId = data['teacherId'] as String?;

            // Only count if user is a participant
            if (parentId == userId || teacherId == userId) {
              // Check if thread has unread messages for this user
              final unreadField = '${userId}_unread';
              final hasUnread = data[unreadField] ?? true; // Default to unread
              if (hasUnread == true) {
                unreadCount++;
              }
            }
          }
          return unreadCount;
        });
  }

  /// Get unread count for a specific chat thread
  Stream<int> getThreadUnreadCount(String threadId, String currentUserId) {
    return _firestore.collection('chat_threads').doc(threadId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return 0;
      final data = doc.data()!;
      final lastSenderId = data['lastMessageSenderId'] as String?;
      if (lastSenderId != null && lastSenderId != currentUserId) {
        final unreadField = '${currentUserId}_unread';
        return (data[unreadField] ?? 1) as int;
      }
      return 0;
    });
  }

  /// Mark thread as read for a user
  Future<void> markThreadAsRead(String threadId, String userId) async {
    await _firestore.collection('chat_threads').doc(threadId).update({
      '${userId}_unread': false,
    });
  }

  /// Update send message to mark unread for recipient
  Future<void> sendMessageWithUnread(
    String threadId,
    ChatMessage message,
    String recipientId,
  ) async {
    await _firestore
        .collection('chat_threads')
        .doc(threadId)
        .collection('messages')
        .add(message.toFirestore());

    // Update thread last message and mark unread for recipient
    await _firestore.collection('chat_threads').doc(threadId).update({
      'lastMessageText': message.text,
      'lastMessageAt': Timestamp.fromDate(message.createdAt),
      'lastMessageSenderId': message.senderId,
      '${recipientId}_unread': true,
    });
  }
}
