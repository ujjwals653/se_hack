import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'chat_attachments';

  /// Uploads a file to Supabase Storage and returns the public URL.
  /// Throws an exception if the upload fails.
  Future<String> uploadChatAttachment(File file, String uid) async {
    final fileName = path.basename(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    // e.g. "uid/1623849182394_image.jpg"
    final storagePath = '$uid/${timestamp}_$fileName';

    // 1. Upload to the public bucket
    await _supabase.storage.from(_bucketName).upload(
      storagePath,
      file,
      fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
    );

    // 2. Get the public URL
    final url = _supabase.storage.from(_bucketName).getPublicUrl(storagePath);
    return url;
  }
}
