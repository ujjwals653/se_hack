import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

import '../models/squad_resource.dart';
import '../models/cached_resource.dart';

class ResourceRepository {
  final _supabase = Supabase.instance.client;
  final _db = FirebaseFirestore.instance;
  late final Box<CachedResource> _cache;

  ResourceRepository() {
    _cache = Hive.box<CachedResource>('resource_cache');
  }

  // ─── UPLOAD ──────────────────────────────────────────────

  Future<SquadResource> uploadResource({
    required String squadId,
    required File file,
    required String subject,
    required String semester,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    
    // Fetch user name
    final userDoc = await _db.collection('users').doc(uid).get();
    final uploaderName = userDoc.exists ? (userDoc.data()?['name'] ?? userDoc.data()?['firstName'] ?? 'Member') : 'Member';
    
    final uuid = const Uuid().v4();
    final fileName = path.basename(file.path);
    final storagePath = 'squads/$squadId/${uuid}_$fileName';
    final fileSizeBytes = await file.length();

    // 1. Upload binary to Supabase Storage
    await _supabase.storage
      .from('squad-resources')
      .upload(storagePath, file,
        fileOptions: FileOptions(
          contentType: _mimeType(fileName),
          upsert: false,
        ));

    // 2. Get signed URL (valid 1 year)
    final signedUrl = await _supabase.storage
      .from('squad-resources')
      .createSignedUrl(storagePath, 60 * 60 * 24 * 365);

    // 3. Write metadata to Firestore
    final docRef = _db.collection('squads').doc(squadId)
      .collection('resources').doc();

    final resource = SquadResource(
      id: docRef.id,
      fileName: fileName,
      supabasePath: storagePath,
      supabaseUrl: signedUrl,
      subject: subject,
      semester: semester,
      uploadedBy: uid,
      uploaderName: uploaderName,
      uploadedAt: DateTime.now(),
      fileSizeBytes: fileSizeBytes,
      fileType: _fileType(fileName),
    );

    await docRef.set(resource.toMap());
    return resource;
  }

  // ─── READ ─────────────────────────────────────────────────

  Stream<List<SquadResource>> watchResources(String squadId) {
    return _db.collection('squads').doc(squadId)
      .collection('resources')
      .orderBy('uploadedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(SquadResource.fromDoc).toList());
  }

  List<CachedResource> getDownloadedResources() {
    return _cache.values.toList()
      ..sort((a, b) => b.downloadedAt.compareTo(a.downloadedAt));
  }

  // ─── DOWNLOAD + CACHE ────────────────────────────────────

  Future<String> downloadAndCache(SquadResource resource, {bool forceCheck = false}) async {
    // Check if already cached
    final existing = _cache.get(resource.id);
    if (existing != null) {
      final localFile = File(existing.localPath);
      if (await localFile.exists()) {
        // Stale check
        if (!forceCheck || !resource.uploadedAt.isAfter(existing.remoteUpdatedAt)) {
          return existing.localPath;
        }
      }
    }

    // Download from Supabase signed URL
    // Here we use createSignedUrl again to ensure we have a fresh URL just in case
    final freshUrl = await _supabase.storage
      .from('squad-resources')
      .createSignedUrl(resource.supabasePath, 60 * 60 * 24 * 365);
      
    final bytes = await _supabase.storage
      .from('squad-resources')
      .download(resource.supabasePath);

    // Save to app documents directory
    final dir = await getApplicationDocumentsDirectory();
    final localPath = '${dir.path}/lumina_resources/${resource.id}_${resource.fileName}';
    final localFile = File(localPath);
    await localFile.parent.create(recursive: true);
    await localFile.writeAsBytes(bytes);

    // Save to Hive cache
    final cached = CachedResource(
      id: resource.id,
      fileName: resource.fileName,
      localPath: localPath,
      subject: resource.subject,
      semester: resource.semester,
      uploaderName: resource.uploaderName,
      downloadedAt: DateTime.now(),
      fileType: resource.fileType,
      remoteUpdatedAt: resource.uploadedAt,
    );
    await _cache.put(resource.id, cached);

    // Queue for RAG indexing if PDF
    if (resource.fileType == 'pdf') {
      await _queueForRAG(localPath, resource.subject);
    }

    return localPath;
  }

  // ─── DELETE ───────────────────────────────────────────────

  Future<void> deleteResource(String squadId, SquadResource resource) async {
    try {
      await _supabase.storage
        .from('squad-resources')
        .remove([resource.supabasePath]);
    } catch (_) {
      // Ignore if not present in Supabase
    }

    await _db.collection('squads').doc(squadId)
      .collection('resources').doc(resource.id).delete();

    final cached = _cache.get(resource.id);
    if (cached != null) {
      final file = File(cached.localPath);
      if (await file.exists()) await file.delete();
      await _cache.delete(resource.id);
    }
  }

  // ─── OPEN FILE ────────────────────────────────────────────

  Future<void> openResource(SquadResource resource) async {
    final localPath = await downloadAndCache(resource);
    await OpenFilex.open(localPath);
  }

  // ─── HELPERS ─────────────────────────────────────────────

  bool isDownloaded(String resourceId) {
    final cached = _cache.get(resourceId);
    if (cached == null) return false;
    return File(cached.localPath).existsSync();
  }

  /// Saves a locally-picked file directly into the Hive drive (no Supabase).
  Future<void> saveLocal(CachedResource resource) async {
    await _cache.put(resource.id, resource);
  }

  /// Removes a locally-saved file from Hive by id.
  Future<void> deleteLocal(String id) async {
    await _cache.delete(id);
  }

  Future<void> _queueForRAG(String localPath, String subject) async {
    final prefs = await SharedPreferences.getInstance();
    final queue = prefs.getStringList('rag_index_queue') ?? [];
    queue.add(jsonEncode({'path': localPath, 'subject': subject}));
    await prefs.setStringList('rag_index_queue', queue);
  }

  String _mimeType(String fileName) {
    if (fileName.endsWith('.pdf')) return 'application/pdf';
    if (fileName.endsWith('.png')) return 'image/png';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  String _fileType(String fileName) {
    if (fileName.endsWith('.pdf')) return 'pdf';
    if (['.png','.jpg','.jpeg','.webp'].any(fileName.endsWith)) return 'image';
    return 'other';
  }
}
