import 'dart:io';
import 'package:flutter/material.dart';
import 'package:se_hack/core/services/theme_service.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/storage_service.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/models/friend_model.dart';
import '../../friends/models/direct_message_model.dart';
import '../../group_hub/models/chat_message_model.dart' show MessageType;
import 'user_profile_view_screen.dart';

class FriendChatScreen extends StatefulWidget {
  final Friend friend;

  const FriendChatScreen({super.key, required this.friend});

  @override
  State<FriendChatScreen> createState() => _FriendChatScreenState();
}

class _FriendChatScreenState extends State<FriendChatScreen> {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _friendsRepo = FriendsRepository();
  final _myUid = FirebaseAuth.instance.currentUser!.uid;

  MessageType _msgType = MessageType.text;
  bool _sending = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  final _storage = StorageService();

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty && _msgType != MessageType.image && _msgType != MessageType.file) return;
    setState(() => _sending = true);
    _msgCtrl.clear();
    try {
      await _friendsRepo.sendDM(widget.friend.uid, text, _msgType);
      _scrollToBottom();
      setState(() => _msgType = MessageType.text); // reset type
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: ImageSource.gallery);
    if (xFile == null) return;
    final file = File(xFile.path);

    setState(() => _sending = true);
    try {
      final url = await _storage.uploadChatAttachment(file, _myUid);
      await _friendsRepo.sendDM(
        widget.friend.uid,
        'Photo',
        MessageType.image,
        fileUrl: url,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Error: $e')));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _pickAndUploadDocument() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);

    setState(() => _sending = true);
    try {
      final url = await _storage.uploadChatAttachment(file, _myUid);
      await _friendsRepo.sendDM(
        widget.friend.uid,
        result.files.single.name,
        MessageType.file,
        fileUrl: url,
        fileName: result.files.single.name,
        fileSize: result.files.single.size,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload Error: $e')));
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Photo/Video'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.insert_drive_file),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadDocument();
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (widget.friend.status) {
      case UserStatus.online:
        return Colors.greenAccent;
      case UserStatus.idle:
        return Colors.amber;
      case UserStatus.invisible:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        foregroundColor: context.textPrimary,
        elevation: 0,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileViewScreen(uid: widget.friend.uid),
              ),
            );
          },
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: _primary.withOpacity(0.1),
                    backgroundImage: widget.friend.photoUrl != null
                        ? NetworkImage(widget.friend.photoUrl!)
                        : null,
                    child: widget.friend.photoUrl == null
                        ? Text(
                            widget.friend.displayName[0],
                            style: const TextStyle(color: _primary),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getStatusColor(),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.friend.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.friend.status.name,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Message type selector
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                _TypeChip(
                  label: '💬 Text',
                  selected: _msgType == MessageType.text,
                  onTap: () => setState(() => _msgType = MessageType.text),
                ),
                const SizedBox(width: 8),
                _TypeChip(
                  label: '</> Code',
                  selected: _msgType == MessageType.code,
                  onTap: () => setState(() => _msgType = MessageType.code),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<DirectMessage>>(
              stream: _friendsRepo.watchDMs(widget.friend.uid),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
                  );
                }
                final msgs = snap.data!;
                _scrollToBottom();
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg = msgs[i];
                    final isMe = msg.senderId == _myUid;
                    return _DirectMessageBubble(
                      message: msg,
                      isMe: isMe,
                      onDelete: () async {
                        await _friendsRepo.deleteDM(widget.friend.uid, msg.id);
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Input area
          Container(
            padding: EdgeInsets.fromLTRB(
              12,
              8,
              12,
              MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 32,
            ),
            decoration: BoxDecoration(
              color: context.chatInputBarBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: context.chatInputBg,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgCtrl,
                        maxLines: _msgType == MessageType.code ? 4 : 1,
                        minLines: 1,
                        style: _msgType == MessageType.code
                            ? const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 13,
                              )
                            : null,
                        decoration: InputDecoration(
                          prefixIcon: IconButton(
                            icon: const Icon(Icons.attach_file, color: Colors.grey),
                            onPressed: _showAttachmentOptions,
                          ),
                          hintText: _msgType == MessageType.code
                              ? 'Paste code here...'
                              : 'Message...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        // Only submit on enter for text messages, allow newlines for code.
                        onSubmitted: _msgType == MessageType.text
                            ? (_) => _send()
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _primary,
                      shape: BoxShape.circle,
                    ),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : IconButton(
                            onPressed: _send,
                            icon: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
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

class _DirectMessageBubble extends StatelessWidget {
  final DirectMessage message;
  final bool isMe;
  final VoidCallback onDelete;
  static const Color _primary = Color(0xFF4C4D7B);

  const _DirectMessageBubble({
    required this.message,
    required this.isMe,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCode = message.type == MessageType.code;

    return GestureDetector(
      onLongPress: () {
        if (isMe && !message.isDeleted) {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Delete Message', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isCode ? 12 : 14,
                    vertical: isCode ? 10 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: isCode
                        ? const Color(0xFF1E1E2E)
                        : isMe
                        ? _primary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                  ),
                  child: message.isDeleted
                      ? Text(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.black54,
                            fontStyle: FontStyle.italic,
                            fontSize: 14,
                          ),
                        )
                      : isCode
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '</> Code',
                                  style: TextStyle(
                                    color: Color(0xFF7B61FF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    Clipboard.setData(
                                      ClipboardData(text: message.text),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Copied!')),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.copy,
                                    size: 14,
                                    color: Colors.white38,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SelectableText(
                              message.text,
                              style: const TextStyle(
                                color: Color(0xFFE8E8E8),
                                fontFamily: 'monospace',
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        )
                      : message.type == MessageType.image && message.fileUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: message.fileUrl!,
                                width: 200,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const SizedBox(
                                    width: 200, height: 200, child: Center(child: CircularProgressIndicator())),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            )
                      : message.type == MessageType.file && message.fileUrl != null
                          ? GestureDetector(
                              onTap: () async {
                                final uri = Uri.parse(message.fileUrl!);
                                if (await canLaunchUrl(uri)) await launchUrl(uri);
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.insert_drive_file, color: isMe ? Colors.white : Colors.grey, size: 28),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          message.fileName ?? 'Document',
                                          style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (message.fileSize != null)
                                          Text(
                                            '${(message.fileSize! / 1024).toStringAsFixed(1)} KB',
                                            style: TextStyle(color: isMe ? Colors.white70 : Colors.black54, fontSize: 11),
                                          ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                      : Text(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${t.day}/${t.month}';
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  static const Color _primary = Color(0xFF4C4D7B);

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _primary : context.surfaceBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}
