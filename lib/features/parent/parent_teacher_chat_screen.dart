import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../models/chat_model.dart';
import '../../core/theme.dart';

class ParentTeacherChatScreen extends StatefulWidget {
  final String currentUserId;
  final String currentUserRole; // 'parent' or 'teacher'
  final String parentId;
  final String teacherId;
  final String studentId;
  final String studentName;

  const ParentTeacherChatScreen({
    super.key,
    required this.currentUserId,
    required this.currentUserRole,
    required this.parentId,
    required this.teacherId,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<ParentTeacherChatScreen> createState() =>
      _ParentTeacherChatScreenState();
}

class _ParentTeacherChatScreenState extends State<ParentTeacherChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _threadId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    final dbService = Provider.of<DatabaseService>(context, listen: false);

    final existingThread = await dbService.getChatThread(
      widget.parentId,
      widget.teacherId,
      widget.studentId,
    );

    if (existingThread != null) {
      setState(() {
        _threadId = existingThread.threadId;
        _isLoading = false;
      });

      // Mark as read when entering chat
      await dbService.markThreadAsRead(_threadId!, widget.currentUserId);
    } else {
      final thread = ChatThread(
        threadId: '',
        parentId: widget.parentId,
        teacherId: widget.teacherId,
        studentId: widget.studentId,
        lastMessageAt: DateTime.now(),
        lastMessageText: '',
        lastMessageSenderId: '',
      );

      final id = await dbService.createChatThread(thread);
      setState(() {
        _threadId = id;
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _threadId == null) return;

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final notificationService = Provider.of<NotificationService>(
      context,
      listen: false,
    );

    final messageText = _messageController.text.trim();
    final message = ChatMessage(
      messageId: '',
      senderId: widget.currentUserId,
      senderRole: widget.currentUserRole,
      text: messageText,
      createdAt: DateTime.now(),
    );

    // Determine recipient
    final recipientId =
        widget.currentUserRole == 'parent' ? widget.teacherId : widget.parentId;

    // Send message and mark unread for recipient
    await dbService.sendMessageWithUnread(_threadId!, message, recipientId);
    _messageController.clear();

    // Send push notification to receiver
    final senderName =
        widget.currentUserRole == 'parent' ? 'Parent' : 'Teacher';

    await notificationService.sendNotificationToUser(
      userId: recipientId,
      title: 'New message from $senderName',
      body: messageText,
      type: 'chat',
      relatedId: _threadId!,
    );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Chat: ${widget.studentName}')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final dbService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chat about ${widget.studentName}'),
            Text(
              widget.currentUserRole == 'parent'
                  ? 'Chatting with Teacher'
                  : 'Chatting with Parent',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: dbService.getChatMessages(_threadId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!;

                // Auto-scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == widget.currentUserId;

                    return _MessageBubble(
                      message: message.text,
                      isMe: isMe,
                      timestamp: message.createdAt,
                      senderLabel:
                          isMe
                              ? 'You'
                              : (widget.currentUserRole == 'parent'
                                  ? 'Teacher'
                                  : 'Parent'),
                    );
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final String senderLabel;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.timestamp,
    required this.senderLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.accentOrange,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: isMe ? AppTheme.primaryGradient : null,
                    color: isMe ? null : Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(timestamp),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.primaryLight,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ],
      ),
    );
  }
}
