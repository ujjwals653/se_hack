import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../bloc/posts_bloc.dart';
import '../../data/post_model.dart';
import '../widgets/post_card.dart';
import '../create_post_screen.dart';
import '../post_detail_screen.dart';

/// Reddit-style posts feed with pull-to-refresh and FAB.
class PostsScreen extends StatelessWidget {
  final String currentUid;
  final String currentUserName;
  final String? currentUserPhotoUrl;

  const PostsScreen({
    super.key,
    required this.currentUid,
    required this.currentUserName,
    this.currentUserPhotoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5FA),
      body: Column(
        children: [
          // ── Header ──
          Container(
            padding: EdgeInsets.fromLTRB(20, topPad + 12, 20, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF6B35), size: 18),
                       const SizedBox(width: 4),
                       Text(
                         'Community',
                         style: GoogleFonts.inter(
                           color: const Color(0xFFFF6B35),
                           fontSize: 12,
                           fontWeight: FontWeight.w700,
                         ),
                       ),
                     ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Posts',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A1A2E),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Feed ──
          Expanded(
            child: BlocBuilder<PostsBloc, PostsState>(
              builder: (context, state) {
                if (state is PostsLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4C4D7B),
                    ),
                  );
                }

                if (state is PostsError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.grey.shade400, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          'Something went wrong',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () =>
                              context.read<PostsBloc>().add(LoadPosts()),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                List<PostModel> posts = [];
                if (state is PostsLoaded) posts = state.posts;
                if (state is PostCreating) posts = state.posts;

                if (posts.isEmpty) {
                  return RefreshIndicator(
                    color: const Color(0xFF4C4D7B),
                    onRefresh: () async {
                      context.read<PostsBloc>().add(RefreshPosts());
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.5,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.post_add_rounded,
                                    color: Colors.grey.shade300, size: 64),
                                const SizedBox(height: 16),
                                Text(
                                  'No posts yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Be the first to share something!',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade400,
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

                return RefreshIndicator(
                  color: const Color(0xFFFF6B35),
                  onRefresh: () async {
                    context.read<PostsBloc>().add(RefreshPosts());
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    itemCount: posts.length + (state is PostCreating ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Show a loading card at the top when creating
                      if (state is PostCreating && index == 0) {
                        return Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border:
                                Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFFF6B35),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Publishing your post…',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final postIndex =
                          state is PostCreating ? index - 1 : index;
                      final post = posts[postIndex];

                      return PostCard(
                        post: post,
                        currentUid: currentUid,
                        onUpvote: () => context.read<PostsBloc>().add(
                              ToggleUpvote(
                                  postId: post.id, uid: currentUid),
                            ),
                        onDownvote: () => context.read<PostsBloc>().add(
                              ToggleDownvote(
                                  postId: post.id, uid: currentUid),
                            ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(
                                post: post,
                                currentUid: currentUid,
                                currentUserName: currentUserName,
                                currentUserPhotoUrl: currentUserPhotoUrl,
                              ),
                            ),
                          );
                        },
                        onDelete: post.authorUid == currentUid
                            ? () => _confirmDelete(context, post.id)
                            : null,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 72),
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFFF6B35),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<PostsBloc>(),
                  child: CreatePostScreen(
                    currentUid: currentUid,
                    currentUserName: currentUserName,
                    currentUserPhotoUrl: currentUserPhotoUrl,
                  ),
                ),
              ),
            );
          },
          child: const Icon(Icons.edit_rounded, size: 24),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<PostsBloc>().add(DeletePost(postId: postId));
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
