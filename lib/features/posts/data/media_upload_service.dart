import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads images / videos to the Supabase `post-media` storage bucket
/// and returns publicly-accessible URLs.
class MediaUploadService {
  static const _bucket = 'post-media';

  final SupabaseClient _client;

  MediaUploadService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Upload a file and return its public URL.
  ///
  /// [file]     – local file from image_picker / file_picker.
  /// [userId]   – used to namespace uploads.
  /// [fileName] – original file name (extension is preserved).
  Future<String> uploadFile({
    required File file,
    required String userId,
    required String fileName,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ext = fileName.split('.').last;
    final storagePath = 'posts/$userId/${timestamp}_$fileName';

    await _client.storage.from(_bucket).upload(
          storagePath,
          file,
          fileOptions: FileOptions(
            contentType: _mimeType(ext),
            upsert: true,
          ),
        );

    final publicUrl =
        _client.storage.from(_bucket).getPublicUrl(storagePath);

    return publicUrl;
  }

  /// Upload multiple files and return their public URLs.
  Future<List<String>> uploadFiles({
    required List<File> files,
    required List<String> fileNames,
    required String userId,
  }) async {
    final urls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final url = await uploadFile(
        file: files[i],
        userId: userId,
        fileName: fileNames[i],
      );
      urls.add(url);
    }
    return urls;
  }

  /// Delete a file by its storage path extracted from the public URL.
  Future<void> deleteFile(String publicUrl) async {
    // Public URL format: .../storage/v1/object/public/post-media/<path>
    final uri = Uri.parse(publicUrl);
    final segments = uri.pathSegments;
    final bucketIdx = segments.indexOf(_bucket);
    if (bucketIdx == -1) return;
    final path = segments.sublist(bucketIdx + 1).join('/');
    await _client.storage.from(_bucket).remove([path]);
  }

  String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      default:
        return 'application/octet-stream';
    }
  }
}
