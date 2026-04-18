import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';

import '../repositories/resource_repository.dart';
import '../models/cached_resource.dart';

class OfflineDriveScreen extends StatefulWidget {
  const OfflineDriveScreen({super.key});

  @override
  State<OfflineDriveScreen> createState() => _OfflineDriveScreenState();
}

class _OfflineDriveScreenState extends State<OfflineDriveScreen> {
  final _repo = ResourceRepository();
  static const Color _primary = Color(0xFF4C4D7B);

  @override
  Widget build(BuildContext context) {
    final cached = _repo.getDownloadedResources();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        title: const Text('Offline Drive'),
        centerTitle: true,
      ),
      body: cached.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.folder_off_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No files downloaded yet.\nFiles you download will appear here offline. 📥',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cached.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _OfflineTile(resource: cached[i], repo: _repo),
            ),
    );
  }
}

class _OfflineTile extends StatelessWidget {
  final CachedResource resource;
  final ResourceRepository repo;

  const _OfflineTile({required this.resource, required this.repo});

  @override
  Widget build(BuildContext context) {
    final isPdf = resource.fileType == 'pdf';
    final isImg = resource.fileType == 'image';
    final emoji = isPdf ? '📄' : isImg ? '🖼️' : '📁';

    // File size can be calculated
    final localFile = File(resource.localPath);
    final sizeStr = localFile.existsSync() 
        ? '${(localFile.lengthSync() / 1024).toStringAsFixed(0)} KB' 
        : 'Unknown Size';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 28)),
        title: Text(resource.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${resource.subject} · ${resource.uploaderName} · $sizeStr\nDownloaded: ${DateFormat('d MMM, HH:mm').format(resource.downloadedAt)}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.3),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.offline_pin_rounded, color: Color(0xFF1D9E75), size: 20),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF4C4D7B)),
              onPressed: () {
                OpenFilex.open(resource.localPath);
              },
            ),
          ],
        ),
      ),
    );
  }
}
