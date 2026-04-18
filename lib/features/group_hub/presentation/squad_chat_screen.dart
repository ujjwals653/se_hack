import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/storage_service.dart';
import '../data/squad_repository.dart';
import '../models/chat_message_model.dart';
import '../../resources/repositories/resource_repository.dart';

class SquadChatScreen extends StatefulWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  final String squadName;

  const SquadChatScreen({
    super.key,
    required this.squadId,
    required this.uid,
    required this.repo,
    required this.squadName,
  });

  @override
  State<SquadChatScreen> createState() => _SquadChatScreenState();
}

class _SquadChatScreenState extends State<SquadChatScreen>
    with SingleTickerProviderStateMixin {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  final _msgCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late TabController _tabs;
  MessageType _msgType = MessageType.text;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    _tabs.dispose();
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
      await widget.repo.sendMessage(widget.squadId, _msgType, text);
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
      final url = await _storage.uploadChatAttachment(file, widget.uid);
      await widget.repo.sendMessage(
        widget.squadId,
        MessageType.image,
        'Photo',
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);

    // Show tag sheet for resource vault
    final tags = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ResourceTagSheetDummy(), 
    );
    if (tags == null) return;

    setState(() => _sending = true);
    try {
      final res = await ResourceRepository().uploadResource(
        squadId: widget.squadId,
        file: file,
        subject: tags['subject']!,
        semester: tags['semester']!,
      );
      
      await widget.repo.sendMessage(
        widget.squadId,
        MessageType.file,
        res.fileName,
        fileUrl: res.supabaseUrl,
        fileName: res.fileName,
        fileSize: res.fileSizeBytes,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A2E),
        bottom: TabBar(
          controller: _tabs,
          labelColor: _primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _accent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: '💬 Chat'),
            Tab(text: '📌 Pasteboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // ── Chat tab ───────────────────────────────────────────────
          Column(
            children: [
              // Message type selector
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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

              // Messages
              Expanded(
                child: StreamBuilder<List<ChatMessage>>(
                  stream: widget.repo.watchMessages(widget.squadId),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7B61FF),
                        ),
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
                        final isMe = msg.uid == widget.uid;
                        return _MessageBubble(
                          message: msg,
                          isMe: isMe,
                          onPin: () async {
                            await widget.repo.pinMessage(
                              widget.squadId,
                              msg.id,
                              !msg.pinned,
                            );
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
                  MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 100,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
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
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: _msgCtrl,
                            maxLines: _msgType == MessageType.code ? 4 : 1,
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
                                  : 'Type a message...',
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
                            onSubmitted: (_) => _send(),
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

          // ── Pasteboard tab ─────────────────────────────────────────
          _PasteboardTab(squadId: widget.squadId, repo: widget.repo),
        ],
      ),
    );
  }
}

// ─── Message Bubble ──────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final VoidCallback onPin;
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    final isCode = message.type == MessageType.code;

    return GestureDetector(
      onLongPress: () => _showActions(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  (message.senderName?.isNotEmpty == true
                          ? message.senderName![0]
                          : '?')
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4C4D7B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.senderName ?? 'Member',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (message.pinned) ...[
                            const SizedBox(width: 4),
                            const Text('📌', style: TextStyle(fontSize: 10)),
                          ],
                        ],
                      ),
                    ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
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
                    child: isCode
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '</> Code',
                                    style: TextStyle(
                                      color: Color(0xFF7B61FF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(
                                        ClipboardData(text: message.content),
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Copied to clipboard'),
                                        ),
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
                                message.content,
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
                            message.content,
                            style: TextStyle(
                              color: isMe ? Colors.white : Colors.black87,
                              fontSize: 14,
                              height: 1.4,
                            ),
                          ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            if (isMe) const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  void _showActions(BuildContext context) {
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
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(message.pinned ? 'Unpin' : 'Pin to Pasteboard'),
              onTap: () {
                Navigator.pop(context);
                onPin();
              },
            ),
            if (message.type == MessageType.code)
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Code'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: message.content));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Copied!')));
                },
              ),
            const SizedBox(height: 8),
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

// ─── Type Chip ────────────────────────────────────────────────────────────────
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
          color: selected ? _primary : Colors.grey.shade100,
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

// ─── Pasteboard Tab ──────────────────────────────────────────────────────────
class _PasteboardTab extends StatelessWidget {
  final String squadId;
  final SquadRepository repo;
  const _PasteboardTab({required this.squadId, required this.repo});

  static const Color _primary = Color(0xFF4C4D7B);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatMessage>>(
      stream: repo.watchPinned(squadId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF7B61FF)),
          );
        }
        final pinned = snap.data!;
        if (pinned.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📌', style: TextStyle(fontSize: 48)),
                SizedBox(height: 12),
                Text(
                  'No pinned messages yet',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  'Long-press a message to pin it here',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: pinned.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final msg = pinned[i];
            final isCode = msg.type == MessageType.code;
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isCode ? const Color(0xFF1E1E2E) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCode ? Colors.transparent : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('📌', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        msg.senderName ?? 'Member',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCode
                              ? const Color(0xFF7B61FF)
                              : Colors.grey.shade600,
                        ),
                      ),
                      const Spacer(),
                      if (isCode)
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: msg.content));
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
                  Text(
                    msg.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: isCode ? const Color(0xFFE8E8E8) : Colors.black87,
                      fontFamily: isCode ? 'monospace' : null,
                      height: 1.4,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ResourceTagSheetDummy extends StatefulWidget {
  @override
  State<_ResourceTagSheetDummy> createState() => _ResourceTagSheetDummyState();
}

class _ResourceTagSheetDummyState extends State<_ResourceTagSheetDummy> {
  String _subject = 'Other';
  String _semester = 'Sem 1';
  final _subjects = ['DSA', 'DBMS', 'OS', 'Maths', 'CN', 'Other'];
  final _semesters = ['Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Sem 5', 'Sem 6'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tag Document', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _subject,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _subject = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _semester,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    items: _semesters.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => setState(() => _semester = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C4D7B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm & Upload'),
                onPressed: () {
                  Navigator.pop(context, {'subject': _subject, 'semester': _semester});
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

