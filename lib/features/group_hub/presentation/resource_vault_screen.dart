import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

import 'package:open_filex/open_filex.dart';

import '../../resources/models/squad_resource.dart';
import '../../resources/repositories/resource_repository.dart';

class ResourceVaultScreen extends StatelessWidget {
  final String squadId;
  final String uid; // Kept for compatibility if needed

  const ResourceVaultScreen({
    super.key,
    required this.squadId,
    required this.uid,
    dynamic repo, // Ignored, using the new one
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF4C4D7B),
          foregroundColor: Colors.white,
          title: const Text('Resource Vault'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Squad Vault'),
              Tab(text: 'Downloaded'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.upload_rounded),
              onPressed: () => _pickAndUpload(context, squadId),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _SquadVaultTab(squadId: squadId),
            _DownloadedTab(),
          ],
        ),
      ),
    );
  }

  void _pickAndUpload(BuildContext context, String squadId) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'docx', 'txt'],
    );
    if (result == null) return;

    final file = File(result.files.single.path!);

    final tags = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _ResourceTagSheet(),
    );
    if (tags == null) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Uploading...')));

    try {
      await ResourceRepository().uploadResource(
        squadId: squadId,
        file: file,
        subject: tags['subject']!,
        semester: tags['semester']!,
      );
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload complete! ✅')));
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }
}

class _ResourceTagSheet extends StatefulWidget {
  const _ResourceTagSheet();
  @override
  State<_ResourceTagSheet> createState() => _ResourceTagSheetState();
}

class _ResourceTagSheetState extends State<_ResourceTagSheet> {
  String _subject = 'Other';
  String _semester = 'Sem 1';
  final _subjects = ['DSA', 'DBMS', 'OS', 'Maths', 'CN', 'Other'];
  final _semesters = [
    'Sem 1',
    'Sem 2',
    'Sem 3',
    'Sem 4',
    'Sem 5',
    'Sem 6'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
          ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tag File',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _subject,
                    decoration: const InputDecoration(labelText: 'Subject'),
                    items: _subjects
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _subject = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _semester,
                    decoration: const InputDecoration(labelText: 'Semester'),
                    items: _semesters
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _semester = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4C4D7B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
                onPressed: () {
                  Navigator.pop(
                      context, {'subject': _subject, 'semester': _semester});
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// ─── Squad Vault Tab ────────────────────────────────────────

class _SquadVaultTab extends StatelessWidget {
  final String squadId;
  const _SquadVaultTab({required this.squadId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SquadResource>>(
      stream: ResourceRepository().watchResources(squadId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final resources = snap.data!;

        if (resources.isEmpty) {
          return const Center(
            child: Text(
              'No resources yet.\nUpload something for your squad! 📚',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          itemCount: resources.length,
          itemBuilder: (_, i) =>
              ResourceVaultTile(resource: resources[i], squadId: squadId),
        );
      },
    );
  }
}

// ─── Downloaded Tab ─────────────────────────────────────────

class _DownloadedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cached = ResourceRepository().getDownloadedResources();

    if (cached.isEmpty) {
      return const Center(
        child: Text(
          'No files downloaded yet.\nFiles you download are available offline here. 📥',
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: cached.length,
      itemBuilder: (_, i) => _OfflineTile(resource: cached[i]),
    );
  }
}

class ResourceVaultTile extends StatelessWidget {
  final SquadResource resource;
  final String squadId;
  final _repo = ResourceRepository();

  ResourceVaultTile({super.key, required this.resource, required this.squadId});

  @override
  Widget build(BuildContext context) {
    final downloaded = _repo.isDownloaded(resource.id);
    final emoji = resource.fileType == 'pdf'
        ? '📄'
        : resource.fileType == 'image'
            ? '🖼️'
            : '📁';
    final size = '${(resource.fileSizeBytes / 1024).toStringAsFixed(0)} KB';

    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 28)),
      title:
          Text(resource.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${resource.subject} · ${resource.uploaderName} · $size'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (downloaded)
            const Icon(Icons.offline_pin_rounded,
                color: Color(0xFF1D9E75), size: 18),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('Opening...')));
              _repo.openResource(resource).catchError((e) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              });
            },
          ),
        ],
      ),
    );
  }
}

class _OfflineTile extends StatelessWidget {
  final dynamic resource;
  const _OfflineTile({required this.resource});

  @override
  Widget build(BuildContext context) {
    final emoji = resource.fileType == 'pdf'
        ? '📄'
        : resource.fileType == 'image'
            ? '🖼️'
            : '📁';

    // File size can be calculated
    final localFile = File(resource.localPath);
    final sizeStr = localFile.existsSync() 
        ? '${(localFile.lengthSync() / 1024).toStringAsFixed(0)} KB' 
        : 'Unknown Size';

    return ListTile(
      leading: Text(emoji, style: const TextStyle(fontSize: 28)),
      title: Text(resource.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${resource.subject} · ${resource.uploaderName} · $sizeStr',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF4C4D7B)),
        onPressed: () {
          OpenFilex.open(resource.localPath);
        },
      ),
    );
  }
}
