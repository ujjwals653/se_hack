import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_model.dart';
import 'comment_model.dart';

/// Firestore repository for posts and threaded comments.
class PostsRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _postsCol => _db.collection('posts');

  CollectionReference _commentsCol(String postId) =>
      _postsCol.doc(postId).collection('comments');

  // ─── Posts ──────────────────────────────────────────────────────────────────

  /// Real-time stream of all posts, newest first.
  Stream<List<PostModel>> watchPosts() {
    return _postsCol
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(PostModel.fromDoc).toList());
  }

  /// One-shot fetch (used by pull-to-refresh).
  Future<List<PostModel>> fetchPosts() async {
    final snapshot =
        await _postsCol.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(PostModel.fromDoc).toList();
  }

  Future<void> createPost(PostModel post) async {
    await _postsCol.doc(post.id).set(post.toMap());
  }

  Future<void> deletePost(String postId) async {
    // Delete all comments first
    final comments = await _commentsCol(postId).get();
    final batch = _db.batch();
    for (final doc in comments.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_postsCol.doc(postId));
    await batch.commit();
  }

  // ─── Voting ────────────────────────────────────────────────────────────────

  Future<void> toggleUpvote(String postId, String uid) async {
    final ref = _postsCol.doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final post = PostModel.fromDoc(snap);

      final upvoted = List<String>.from(post.upvotedBy);
      final downvoted = List<String>.from(post.downvotedBy);
      int ups = post.upvotes;
      int downs = post.downvotes;

      if (upvoted.contains(uid)) {
        // Remove upvote
        upvoted.remove(uid);
        ups--;
      } else {
        // Add upvote, remove downvote if present
        upvoted.add(uid);
        ups++;
        if (downvoted.contains(uid)) {
          downvoted.remove(uid);
          downs--;
        }
      }

      tx.update(ref, {
        'upvotes': ups,
        'downvotes': downs,
        'upvotedBy': upvoted,
        'downvotedBy': downvoted,
      });
    });
  }

  Future<void> toggleDownvote(String postId, String uid) async {
    final ref = _postsCol.doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final post = PostModel.fromDoc(snap);

      final upvoted = List<String>.from(post.upvotedBy);
      final downvoted = List<String>.from(post.downvotedBy);
      int ups = post.upvotes;
      int downs = post.downvotes;

      if (downvoted.contains(uid)) {
        downvoted.remove(uid);
        downs--;
      } else {
        downvoted.add(uid);
        downs++;
        if (upvoted.contains(uid)) {
          upvoted.remove(uid);
          ups--;
        }
      }

      tx.update(ref, {
        'upvotes': ups,
        'downvotes': downs,
        'upvotedBy': upvoted,
        'downvotedBy': downvoted,
      });
    });
  }

  // ─── Comments (threaded) ───────────────────────────────────────────────────

  /// Stream all comments for a post, ordered by creation time.
  Stream<List<CommentModel>> watchComments(String postId) {
    return _commentsCol(postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map(CommentModel.fromDoc).toList());
  }

  Future<void> addComment(CommentModel comment) async {
    final batch = _db.batch();
    batch.set(
      _commentsCol(comment.postId).doc(comment.id),
      comment.toMap(),
    );
    // Increment comment count on the parent post
    batch.update(
      _postsCol.doc(comment.postId),
      {'commentCount': FieldValue.increment(1)},
    );
    await batch.commit();
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final batch = _db.batch();
    batch.delete(_commentsCol(postId).doc(commentId));
    batch.update(
      _postsCol.doc(postId),
      {'commentCount': FieldValue.increment(-1)},
    );
    await batch.commit();
  }

  /// Toggle upvote on a comment.
  Future<void> toggleCommentUpvote(
      String postId, String commentId, String uid) async {
    final ref = _commentsCol(postId).doc(commentId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final comment = CommentModel.fromDoc(snap);

      final upvoted = List<String>.from(comment.upvotedBy);
      final downvoted = List<String>.from(comment.downvotedBy);
      int ups = comment.upvotes;
      int downs = comment.downvotes;

      if (upvoted.contains(uid)) {
        upvoted.remove(uid);
        ups--;
      } else {
        upvoted.add(uid);
        ups++;
        if (downvoted.contains(uid)) {
          downvoted.remove(uid);
          downs--;
        }
      }

      tx.update(ref, {
        'upvotes': ups,
        'downvotes': downs,
        'upvotedBy': upvoted,
        'downvotedBy': downvoted,
      });
    });
  }

  /// Toggle downvote on a comment.
  Future<void> toggleCommentDownvote(
      String postId, String commentId, String uid) async {
    final ref = _commentsCol(postId).doc(commentId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final comment = CommentModel.fromDoc(snap);

      final upvoted = List<String>.from(comment.upvotedBy);
      final downvoted = List<String>.from(comment.downvotedBy);
      int ups = comment.upvotes;
      int downs = comment.downvotes;

      if (downvoted.contains(uid)) {
        downvoted.remove(uid);
        downs--;
      } else {
        downvoted.add(uid);
        downs++;
        if (upvoted.contains(uid)) {
          upvoted.remove(uid);
          ups--;
        }
      }

      tx.update(ref, {
        'upvotes': ups,
        'downvotes': downs,
        'upvotedBy': upvoted,
        'downvotedBy': downvoted,
      });
    });
  }
}
