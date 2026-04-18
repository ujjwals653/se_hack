import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:uuid/uuid.dart';
import '../data/post_model.dart';
import '../data/comment_model.dart';
import '../data/posts_repository.dart';

/// Full post view with threaded comments.
class PostDetailScreen extends StatefulWidget {
  final PostModel post;
  final String currentUid;
  final String currentUserName;
  final String? currentUserPhotoUrl;

  const PostDetailScreen({
    super.key,
    required this.post,
    required this.currentUid,
    required this.currentUserName,
    this.currentUserPhotoUrl,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _repo = PostsRepository();
  final _uuid = const Uuid();
  final _scrollController = ScrollController();
  VideoPlayerController? _videoController;

  /// When replying to a comment, this holds the parent comment ID.
  String? _replyToId;
  String? _replyToAuthor;

  @override
  void initState() {
    super.initState();
    if (widget.post.mediaType == MediaType.video &&
        widget.post.mediaUrls.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(
          Uri.parse(widget.post.mediaUrls.first))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _videoController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setReplyTo(String commentId, String authorName) {
    setState(() {
      _replyToId = commentId;
      _replyToAuthor = authorName;
    });
    _commentController.clear();
    FocusScope.of(context).requestFocus(FocusNode());
    // Slight delay so keyboard shows
    Future.delayed(const Duration(milliseconds: 100), () {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  void _cancelReply() {
    setState(() {
      _replyToId = null;
      _replyToAuthor = null;
    });
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    final comment = CommentModel(
      id: _uuid.v4(),
      postId: widget.post.id,
      parentId: _replyToId,
      authorUid: widget.currentUid,
      authorName: widget.currentUserName,
      authorPhotoUrl: widget.currentUserPhotoUrl,
      body: body,
      createdAt: DateTime.now(),
    );

    _commentController.clear();
    _cancelReply();

    await _repo.addComment(comment);
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF1A1A2E), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Post',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ── Author ──
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor:
                            const Color(0xFF4C4D7B).withOpacity(0.15),
                        backgroundImage: post.authorPhotoUrl != null
                            ? NetworkImage(post.authorPhotoUrl!)
                            : null,
                        child: post.authorPhotoUrl == null
                            ? Text(
                                post.authorName.isNotEmpty
                                    ? post.authorName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Color(0xFF4C4D7B),
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            timeago.format(post.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // ── Title ──
                  if (post.title.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E),
                        height: 1.3,
                      ),
                    ),
                  ],

                  // ── Body ──
                  if (post.body.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      post.body,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade700,
                        height: 1.6,
                      ),
                    ),
                  ],

                  // ── Media ──
                  if (post.mediaType == MediaType.image &&
                      post.mediaUrls.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: CachedNetworkImage(
                        imageUrl: post.mediaUrls.first,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          height: 250,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4C4D7B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],

                  if (post.mediaType == MediaType.video &&
                      _videoController != null &&
                      _videoController!.value.isInitialized) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AspectRatio(
                              aspectRatio:
                                  _videoController!.value.aspectRatio,
                              child: VideoPlayer(_videoController!),
                            ),
                            if (!_videoController!.value.isPlaying)
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 12),

                  // ── Comments Header ──
                  Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Threaded Comments ──
                  StreamBuilder<List<CommentModel>>(
                    stream: _repo.watchComments(post.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF4C4D7B),
                            ),
                          ),
                        );
                      }

                      final allComments = snapshot.data ?? [];
                      if (allComments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.chat_bubble_outline,
                                    color: Colors.grey.shade300, size: 40),
                                const SizedBox(height: 8),
                                Text(
                                  'No comments yet',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // Build thread tree
                      final topLevel = allComments
                          .where((c) => c.parentId == null)
                          .toList();

                      return Column(
                        children: topLevel
                            .map((c) => _buildCommentThread(
                                  comment: c,
                                  allComments: allComments,
                                  depth: 0,
                                ))
                            .toList(),
                      );
                    },
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),

          // ── Comment Input ──
          _buildCommentInput(),
        ],
      ),
    );
  }

  Widget _buildCommentThread({
    required CommentModel comment,
    required List<CommentModel> allComments,
    required int depth,
  }) {
    final replies =
        allComments.where((c) => c.parentId == comment.id).toList();
    final maxDepth = 4; // visual nesting limit

    return Padding(
      padding: EdgeInsets.only(left: depth > 0 ? 20.0 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thread line + comment
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (depth > 0)
                Container(
                  width: 2,
                  height: 60,
                  margin: const EdgeInsets.only(right: 12, top: 4),
                  decoration: BoxDecoration(
                    color: _threadColor(depth),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              Expanded(child: _buildCommentTile(comment)),
            ],
          ),
          // Render child replies
          if (replies.isNotEmpty)
            ...replies.map((r) => _buildCommentThread(
                  comment: r,
                  allComments: allComments,
                  depth: (depth + 1).clamp(0, maxDepth),
                )),
        ],
      ),
    );
  }

  Color _threadColor(int depth) {
    const colors = [
      Color(0xFF4C4D7B),
      Color(0xFFFF6B35),
      Color(0xFF4CAF50),
      Color(0xFFE91E63),
      Color(0xFF2196F3),
    ];
    return colors[depth % colors.length].withOpacity(0.3);
  }

  Widget _buildCommentTile(CommentModel comment) {
    final isOwner = comment.authorUid == widget.currentUid;
    final isUpvoted = comment.upvotedBy.contains(widget.currentUid);
    final isDownvoted = comment.downvotedBy.contains(widget.currentUid);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    const Color(0xFF4C4D7B).withOpacity(0.15),
                backgroundImage: comment.authorPhotoUrl != null
                    ? NetworkImage(comment.authorPhotoUrl!)
                    : null,
                child: comment.authorPhotoUrl == null
                    ? Text(
                        comment.authorName.isNotEmpty
                            ? comment.authorName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4C4D7B),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                comment.authorName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${timeago.format(comment.createdAt, locale: 'en_short')}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              const Spacer(),
              if (isOwner)
                GestureDetector(
                  onTap: () => _repo.deleteComment(
                      comment.postId, comment.id),
                  child: Icon(Icons.delete_outline,
                      size: 16, color: Colors.grey.shade400),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            comment.body,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          // Action row
          Row(
            children: [
              // Vote buttons
              GestureDetector(
                onTap: () => _repo.toggleCommentUpvote(
                    comment.postId, comment.id, widget.currentUid),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  size: 18,
                  color: isUpvoted
                      ? const Color(0xFFFF4500)
                      : Colors.grey.shade400,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '${comment.score}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isUpvoted
                        ? const Color(0xFFFF4500)
                        : isDownvoted
                            ? const Color(0xFF7193FF)
                            : Colors.grey.shade500,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _repo.toggleCommentDownvote(
                    comment.postId, comment.id, widget.currentUid),
                child: Icon(
                  Icons.arrow_downward_rounded,
                  size: 18,
                  color: isDownvoted
                      ? const Color(0xFF7193FF)
                      : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 16),
              // Reply button
              GestureDetector(
                onTap: () =>
                    _setReplyTo(comment.id, comment.authorName),
                child: Row(
                  children: [
                    Icon(Icons.reply_rounded,
                        size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      'Reply',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 8, 8, MediaQuery.of(context).padding.bottom + 8),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply indicator
          if (_replyToAuthor != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4C4D7B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.reply_rounded,
                      size: 14, color: Color(0xFF4C4D7B)),
                  const SizedBox(width: 6),
                  Text(
                    'Replying to $_replyToAuthor',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4C4D7B),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _cancelReply,
                    child: const Icon(Icons.close,
                        size: 16, color: Color(0xFF4C4D7B)),
                  ),
                ],
              ),
            ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  style: const TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: _replyToAuthor != null
                        ? 'Reply to $_replyToAuthor…'
                        : 'Add a comment…',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _submitComment,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4C4D7B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
