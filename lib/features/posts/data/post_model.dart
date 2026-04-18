import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Types of media attachments on a post.
enum MediaType { none, image, video }

/// Firestore-backed model for a single post.
class PostModel extends Equatable {
  final String id;
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String title;
  final String body;
  final List<String> mediaUrls;
  final MediaType mediaType;
  final DateTime createdAt;
  final int upvotes;
  final int downvotes;
  final int commentCount;
  final List<String> upvotedBy;
  final List<String> downvotedBy;

  const PostModel({
    required this.id,
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl,
    required this.title,
    required this.body,
    this.mediaUrls = const [],
    this.mediaType = MediaType.none,
    required this.createdAt,
    this.upvotes = 0,
    this.downvotes = 0,
    this.commentCount = 0,
    this.upvotedBy = const [],
    this.downvotedBy = const [],
  });

  /// Net score displayed on the card.
  int get score => upvotes - downvotes;

  /// Deserialise from a Firestore document snapshot.
  factory PostModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data()! as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      authorUid: d['authorUid'] as String,
      authorName: d['authorName'] as String,
      authorPhotoUrl: d['authorPhotoUrl'] as String?,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      mediaUrls: List<String>.from(d['mediaUrls'] ?? []),
      mediaType: MediaType.values.byName(d['mediaType'] ?? 'none'),
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      upvotes: d['upvotes'] as int? ?? 0,
      downvotes: d['downvotes'] as int? ?? 0,
      commentCount: d['commentCount'] as int? ?? 0,
      upvotedBy: List<String>.from(d['upvotedBy'] ?? []),
      downvotedBy: List<String>.from(d['downvotedBy'] ?? []),
    );
  }

  /// Serialise to a Firestore-friendly map.
  Map<String, dynamic> toMap() => {
        'authorUid': authorUid,
        'authorName': authorName,
        'authorPhotoUrl': authorPhotoUrl,
        'title': title,
        'body': body,
        'mediaUrls': mediaUrls,
        'mediaType': mediaType.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'upvotes': upvotes,
        'downvotes': downvotes,
        'commentCount': commentCount,
        'upvotedBy': upvotedBy,
        'downvotedBy': downvotedBy,
      };

  PostModel copyWith({
    String? id,
    String? authorUid,
    String? authorName,
    String? authorPhotoUrl,
    String? title,
    String? body,
    List<String>? mediaUrls,
    MediaType? mediaType,
    DateTime? createdAt,
    int? upvotes,
    int? downvotes,
    int? commentCount,
    List<String>? upvotedBy,
    List<String>? downvotedBy,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorUid: authorUid ?? this.authorUid,
      authorName: authorName ?? this.authorName,
      authorPhotoUrl: authorPhotoUrl ?? this.authorPhotoUrl,
      title: title ?? this.title,
      body: body ?? this.body,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      upvotes: upvotes ?? this.upvotes,
      downvotes: downvotes ?? this.downvotes,
      commentCount: commentCount ?? this.commentCount,
      upvotedBy: upvotedBy ?? this.upvotedBy,
      downvotedBy: downvotedBy ?? this.downvotedBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        authorUid,
        authorName,
        authorPhotoUrl,
        title,
        body,
        mediaUrls,
        mediaType,
        createdAt,
        upvotes,
        downvotes,
        commentCount,
        upvotedBy,
        downvotedBy,
      ];
}
