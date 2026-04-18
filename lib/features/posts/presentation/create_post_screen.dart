import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../bloc/posts_bloc.dart';
import '../data/post_model.dart';

/// Screen for composing and submitting a new post with optional media.
class CreatePostScreen extends StatefulWidget {
  final String currentUid;
  final String currentUserName;
  final String? currentUserPhotoUrl;

  const CreatePostScreen({
    super.key,
    required this.currentUid,
    required this.currentUserName,
    this.currentUserPhotoUrl,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _selectedMedia = [];
  MediaType _mediaType = MediaType.none;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1920,
    );
    if (picked != null) {
      setState(() {
        _selectedMedia.clear();
        _selectedMedia.add(picked);
        _mediaType = MediaType.image;
      });
    }
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (picked != null) {
      setState(() {
        _selectedMedia.clear();
        _selectedMedia.add(picked);
        _mediaType = MediaType.video;
      });
    }
  }

  void _removeMedia() {
    setState(() {
      _selectedMedia.clear();
      _mediaType = MediaType.none;
    });
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty && body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a title or some text'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    context.read<PostsBloc>().add(
          CreatePost(
            authorUid: widget.currentUid,
            authorName: widget.currentUserName,
            authorPhotoUrl: widget.currentUserPhotoUrl,
            title: title,
            body: body,
            mediaFiles:
                _selectedMedia.map((x) => File(x.path)).toList(),
            mediaFileNames: _selectedMedia.map((x) => x.name).toList(),
            mediaType: _mediaType,
          ),
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canPost = _titleController.text.trim().isNotEmpty ||
        _bodyController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Post',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isSubmitting ? 0.5 : 1.0,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C4D7B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Post',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      const Color(0xFF4C4D7B).withOpacity(0.15),
                  backgroundImage: widget.currentUserPhotoUrl != null
                      ? NetworkImage(widget.currentUserPhotoUrl!)
                      : null,
                  child: widget.currentUserPhotoUrl == null
                      ? Text(
                          widget.currentUserName.isNotEmpty
                              ? widget.currentUserName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Color(0xFF4C4D7B),
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  widget.currentUserName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Title field
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A2E),
              ),
              decoration: InputDecoration(
                hintText: 'Title',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                border: InputBorder.none,
              ),
              maxLines: null,
              textCapitalization: TextCapitalization.sentences,
            ),

            // Body field
            TextField(
              controller: _bodyController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade800,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText: 'What\'s on your mind?',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                ),
                border: InputBorder.none,
              ),
              maxLines: null,
              minLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),

            // Selected media preview
            if (_selectedMedia.isNotEmpty) ...[
              const SizedBox(height: 16),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _mediaType == MediaType.image
                        ? Image.file(
                            File(_selectedMedia.first.path),
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: double.infinity,
                            height: 220,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade900,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.videocam_rounded,
                                      color: Colors.white54, size: 48),
                                  SizedBox(height: 8),
                                  Text(
                                    'Video selected',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _removeMedia,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
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
        child: Row(
          children: [
            _MediaButton(
              icon: Icons.image_outlined,
              label: 'Image',
              color: const Color(0xFF4CAF50),
              onTap: _pickImage,
            ),
            const SizedBox(width: 12),
            _MediaButton(
              icon: Icons.videocam_outlined,
              label: 'Video',
              color: const Color(0xFFE91E63),
              onTap: _pickVideo,
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
