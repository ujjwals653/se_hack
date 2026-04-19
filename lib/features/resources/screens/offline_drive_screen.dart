import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
  static const Color _accent  = Color(0xFF7B61FF);

  List<CachedResource> _files = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() => setState(() => _files = _repo.getDownloadedResources());

  Future<void> _pickAndSave() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx', 'txt'],
    );
    if (result == null || result.files.isEmpty) return;

    final dir = await getApplicationDocumentsDirectory();
    final driveDir = Directory('${dir.path}/lumina_resources');
    await driveDir.create(recursive: true);

    for (final picked in result.files) {
      if (picked.path == null) continue;
      final src  = File(picked.path!);
      final dest = File('${driveDir.path}/${picked.name}');
      await src.copy(dest.path);

      final id       = picked.name.replaceAll(RegExp(r'\W'), '_');
      final fileType = _fileTypeFromName(picked.name);

      final cached = CachedResource(
        id: id,
        fileName: picked.name,
        localPath: dest.path,
        subject: 'Personal',
        semester: '-',
        uploaderName: 'Me',
        downloadedAt: DateTime.now(),
        fileType: fileType,
        remoteUpdatedAt: DateTime.now(),
      );
      await _repo.saveLocal(cached);
    }
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${result.files.length} file(s) saved to Drive'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _delete(CachedResource r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove from Drive?'),
        content: Text(r.fileName),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final file = File(r.localPath);
    if (await file.exists()) await file.delete();
    await _repo.deleteLocal(r.id);
    _refresh();
  }

  String _fileTypeFromName(String name) {
    final ext = p.extension(name).toLowerCase();
    if (ext == '.pdf') return 'pdf';
    if (['.jpg', '.jpeg', '.png', '.webp'].contains(ext)) return 'image';
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FF),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4C4D7B), _accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        title: const Text('My Drive', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndSave,
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _files.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      color: _accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.folder_open_rounded, size: 40, color: _accent),
                  ),
                  const SizedBox(height: 16),
                  const Text('Drive is empty',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 8),
                  Text('Tap Upload to add PDFs, images or docs.\nThey\'ll be available offline & in Study AI.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14, height: 1.5)),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _files.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _DriveTile(
                resource: _files[i],
                onDelete: () => _delete(_files[i]),
              ),
            ),
    );
  }
}

class _DriveTile extends StatelessWidget {
  final CachedResource resource;
  final VoidCallback onDelete;

  const _DriveTile({required this.resource, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isPdf  = resource.fileType == 'pdf';
    final isImg  = resource.fileType == 'image';
    final icon   = isPdf ? Icons.picture_as_pdf_rounded : isImg ? Icons.image_rounded : Icons.insert_drive_file_rounded;
    final color  = isPdf ? Colors.redAccent : isImg ? Colors.blueAccent : Colors.grey;

    final localFile = File(resource.localPath);
    final sizeStr = localFile.existsSync()
        ? '${(localFile.lengthSync() / 1024).toStringAsFixed(0)} KB'
        : 'File missing';
    final dateStr = DateFormat('d MMM, HH:mm').format(resource.downloadedAt);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(resource.fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('$sizeStr · $dateStr',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new_rounded, size: 20, color: Color(0xFF4C4D7B)),
              tooltip: 'Open',
              onPressed: () => OpenFilex.open(resource.localPath),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
              tooltip: 'Remove',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
