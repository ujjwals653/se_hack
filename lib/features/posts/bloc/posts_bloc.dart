import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import '../data/post_model.dart';
import '../data/comment_model.dart';
import '../data/posts_repository.dart';
import '../data/media_upload_service.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

abstract class PostsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadPosts extends PostsEvent {}

class RefreshPosts extends PostsEvent {}

class CreatePost extends PostsEvent {
  final String authorUid;
  final String authorName;
  final String? authorPhotoUrl;
  final String title;
  final String body;
  final List<File> mediaFiles;
  final List<String> mediaFileNames;
  final MediaType mediaType;

  CreatePost({
    required this.authorUid,
    required this.authorName,
    this.authorPhotoUrl,
    required this.title,
    required this.body,
    this.mediaFiles = const [],
    this.mediaFileNames = const [],
    this.mediaType = MediaType.none,
  });

  @override
  List<Object?> get props =>
      [authorUid, title, body, mediaFiles, mediaType];
}

class ToggleUpvote extends PostsEvent {
  final String postId;
  final String uid;
  ToggleUpvote({required this.postId, required this.uid});
  @override
  List<Object?> get props => [postId, uid];
}

class ToggleDownvote extends PostsEvent {
  final String postId;
  final String uid;
  ToggleDownvote({required this.postId, required this.uid});
  @override
  List<Object?> get props => [postId, uid];
}

class DeletePost extends PostsEvent {
  final String postId;
  DeletePost({required this.postId});
  @override
  List<Object?> get props => [postId];
}

class _PostsUpdated extends PostsEvent {
  final List<PostModel> posts;
  _PostsUpdated(this.posts);
  @override
  List<Object?> get props => [posts];
}

// ─── States ───────────────────────────────────────────────────────────────────

abstract class PostsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PostsInitial extends PostsState {}

class PostsLoading extends PostsState {}

class PostsLoaded extends PostsState {
  final List<PostModel> posts;
  PostsLoaded(this.posts);
  @override
  List<Object?> get props => [posts];
}

class PostCreating extends PostsState {
  final List<PostModel> posts; // keep showing existing posts
  PostCreating(this.posts);
  @override
  List<Object?> get props => [posts];
}

class PostCreated extends PostsState {}

class PostsError extends PostsState {
  final String message;
  PostsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── Bloc ─────────────────────────────────────────────────────────────────────

class PostsBloc extends Bloc<PostsEvent, PostsState> {
  final PostsRepository _repo;
  final MediaUploadService _mediaService;
  final _uuid = const Uuid();
  StreamSubscription<List<PostModel>>? _postsSub;

  PostsBloc({
    PostsRepository? repo,
    MediaUploadService? mediaService,
  })  : _repo = repo ?? PostsRepository(),
        _mediaService = mediaService ?? MediaUploadService(),
        super(PostsInitial()) {
    on<LoadPosts>(_onLoadPosts);
    on<RefreshPosts>(_onRefreshPosts);
    on<CreatePost>(_onCreatePost);
    on<ToggleUpvote>(_onToggleUpvote);
    on<ToggleDownvote>(_onToggleDownvote);
    on<DeletePost>(_onDeletePost);
    on<_PostsUpdated>(_onPostsUpdated);
  }

  void _onLoadPosts(LoadPosts event, Emitter<PostsState> emit) {
    emit(PostsLoading());
    _postsSub?.cancel();
    _postsSub = _repo.watchPosts().listen(
          (posts) => add(_PostsUpdated(posts)),
          onError: (e) => add(_PostsUpdated([])),
        );
  }

  Future<void> _onRefreshPosts(
      RefreshPosts event, Emitter<PostsState> emit) async {
    try {
      final posts = await _repo.fetchPosts();
      emit(PostsLoaded(posts));
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> _onCreatePost(
      CreatePost event, Emitter<PostsState> emit) async {
    final currentPosts =
        state is PostsLoaded ? (state as PostsLoaded).posts : <PostModel>[];
    emit(PostCreating(currentPosts));

    try {
      // Upload media if any
      List<String> mediaUrls = [];
      if (event.mediaFiles.isNotEmpty) {
        mediaUrls = await _mediaService.uploadFiles(
          files: event.mediaFiles,
          fileNames: event.mediaFileNames,
          userId: event.authorUid,
        );
      }

      final post = PostModel(
        id: _uuid.v4(),
        authorUid: event.authorUid,
        authorName: event.authorName,
        authorPhotoUrl: event.authorPhotoUrl,
        title: event.title,
        body: event.body,
        mediaUrls: mediaUrls,
        mediaType: event.mediaType,
        createdAt: DateTime.now(),
      );

      await _repo.createPost(post);
      emit(PostCreated());
      // The stream subscription will push the updated list.
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  Future<void> _onToggleUpvote(
      ToggleUpvote event, Emitter<PostsState> emit) async {
    try {
      await _repo.toggleUpvote(event.postId, event.uid);
    } catch (_) {}
  }

  Future<void> _onToggleDownvote(
      ToggleDownvote event, Emitter<PostsState> emit) async {
    try {
      await _repo.toggleDownvote(event.postId, event.uid);
    } catch (_) {}
  }

  Future<void> _onDeletePost(
      DeletePost event, Emitter<PostsState> emit) async {
    try {
      await _repo.deletePost(event.postId);
    } catch (e) {
      emit(PostsError(e.toString()));
    }
  }

  void _onPostsUpdated(_PostsUpdated event, Emitter<PostsState> emit) {
    emit(PostsLoaded(event.posts));
  }

  @override
  Future<void> close() {
    _postsSub?.cancel();
    return super.close();
  }
}
