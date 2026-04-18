import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Threaded comment model — supports nesting via [parentId].
class CommentModel extends Equatable {
  final String id;
  final String postId;
  final String? parentId; // null ⇒ top-level comment
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String body;
  final DateTime createdAt;
  final int upvotes;
  final int downvotes;
  final List<String> upvotedBy;
  final List<String> downvotedBy;

  const CommentModel({
    required this.id,
    required this.postId,
    this.parentId,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl,
    required this.body,
    required this.createdAt,
    this.upvotes = 0,
    this.downvotes = 0,
    this.upvotedBy = const [],
    this.downvotedBy = const [],
  });

  int get score => upvotes - downvotes;

  factory CommentModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      postId: d['postId'] as String,
      parentId: d['parentId'] as String?,
      authorUid: d['authorUid'] as String,
      authorName: d['authorName'] as String,
      authorPhotoUrl: d['authorPhotoUrl'] as String?,
      body: d['body'] as String,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      upvotes: d['upvotes'] as int? ?? 0,
      downvotes: d['downvotes'] as int? ?? 0,
      upvotedBy: List<String>.from(d['upvotedBy'] ?? []),
      downvotedBy: List<String>.from(d['downvotedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'postId': postId,
        'parentId': parentId,
        'authorUid': authorUid,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'body': body,
        'createdAt': Timestamp.fromDate(createdAt),
        'upvotes': upvotes,
        'downvotes': downvotes,
        'upvotedBy': upvotedBy,
        'downvotedBy': downvotedBy,
      };

  @override
  List<Object?> get props => [
        id,
        postId,
        parentId,
        authorUid,
        authorName,
        authorPhotoUrl,
        body,
        createdAt,
        upvotes,
        downvotes,
        upvotedBy,
        downvotedBy,
      ];
}
