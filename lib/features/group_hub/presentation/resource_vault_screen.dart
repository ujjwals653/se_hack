import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../data/squad_repository.dart';
import '../models/challenge_resource_model.dart';

class ResourceVaultScreen extends StatefulWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  const ResourceVaultScreen(
      {super.key,
      required this.squadId,
      required this.uid,
      required this.repo});

  @override
  State<ResourceVaultScreen> createState() => _ResourceVaultScreenState();
}

class _ResourceVaultScreenState extends State<ResourceVaultScreen> {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  static const _subjects = ['All', 'DSA', 'DBMS', 'OS', 'Maths', 'CN', 'Other'];
  static const _semesters = ['All Sems', 'Sem 1', 'Sem 2', 'Sem 3', 'Sem 4', 'Sem 5', 'Sem 6'];

  String _subjectFilter = 'All';
  String _semesterFilter = 'All Sems';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('📦 Resource Vault',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Filter row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: _subjects
                  .map((s) => _Chip(
                        label: s,
                        selected: _subjectFilter == s,
                        onTap: () => setState(() => _subjectFilter = s),
                        color: _primary,
                      ))
                  .toList(),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: _semesters
                  .map((s) => _Chip(
                        label: s,
                        selected: _semesterFilter == s,
                        onTap: () => setState(() => _semesterFilter = s),
                        color: _accent,
                      ))
                  .toList(),
            ),
          ),

          // Resources list
          Expanded(
            child: StreamBuilder<List<SquadResource>>(
              stream: widget.repo.watchResources(widget.squadId),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF7B61FF)));
                }
                var resources = snap.data!;
                if (_subjectFilter != 'All') {
                  resources = resources
                      .where((r) => r.subject == _subjectFilter)
                      .toList();
                }
                if (_semesterFilter != 'All Sems') {
                  resources = resources
                      .where((r) => r.semester == _semesterFilter)
                      .toList();
                }

                if (resources.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('📦', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Vault is empty',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 15)),
                        SizedBox(height: 4),
                        Text('Upload a file to start sharing resources',
                            style:
                                TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: resources.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final r = resources[i];
                    return _ResourceTile(
                      resource: r,
                      uid: widget.uid,
                      onDelete: r.uploadedBy == widget.uid
                          ? () => widget.repo.deleteResource(
                              widget.squadId, r.id)
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadSheet(context),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_outlined),
        label: const Text('Upload File',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showUploadSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _UploadSheet(
        squadId: widget.squadId,
        uid: widget.uid,
        repo: widget.repo,
        subjects: _subjects.where((s) => s != 'All').toList(),
        semesters: _semesters.where((s) => s != 'All Sems').toList(),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  const _Chip(
      {required this.label,
      required this.selected,
      required this.onTap,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? color : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _ResourceTile extends StatelessWidget {
  final SquadResource resource;
  final String uid;
  final VoidCallback? onDelete;

  const _ResourceTile(
      {required this.resource, required this.uid, this.onDelete});

  static const Color _primary = Color(0xFF4C4D7B);

  @override
  Widget build(BuildContext context) {
    final isPdf = resource.fileType == 'pdf';
    final isImg = resource.fileType == 'image';
    final emoji = isPdf ? '📄' : isImg ? '🖼️' : '📁';
    final bgColor = isPdf
        ? const Color(0xFFD32F2F).withOpacity(0.08)
        : isImg
            ? const Color(0xFF6A1B9A).withOpacity(0.08)
            : Colors.grey.shade50;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.fileName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1A1A2E)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (resource.subject.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: _primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(resource.subject,
                            style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF4C4D7B),
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (resource.semester.isNotEmpty) ...[
                      Text(resource.semester,
                          style: const TextStyle(
                              fontSize: 9, color: Colors.grey)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '· ${resource.uploaderName ?? 'Member'} · ${DateFormat('d MMM').format(resource.uploadedAt)}',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 18, color: Colors.grey),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class _UploadSheet extends StatefulWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  final List<String> subjects;
  final List<String> semesters;
  const _UploadSheet(
      {required this.squadId,
      required this.uid,
      required this.repo,
      required this.subjects,
      required this.semesters});

  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  static const Color _primary = Color(0xFF4C4D7B);
  String? _fileName;
  String _subject = 'Other';
  String _semester = 'Sem 1';
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upload to Vault',
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 14),

              // File picker
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _fileName != null
                          ? _primary
                          : Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _fileName != null
                            ? Icons.check_circle
                            : Icons.upload_file,
                        size: 32,
                        color: _fileName != null ? _primary : Colors.grey,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _fileName ?? 'Tap to select a file',
                        style: TextStyle(
                          fontSize: 13,
                          color: _fileName != null
                              ? const Color(0xFF4C4D7B)
                              : Colors.grey,
                          fontWeight: _fileName != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _subject,
                      decoration: _dec('Subject'),
                      items: widget.subjects
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _subject = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _semester,
                      decoration: _dec('Semester'),
                      items: widget.semesters
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) => setState(() => _semester = v!),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loading || _fileName == null
                      ? null
                      : () => _upload(context),
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Upload',
                          style:
                              TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'docx', 'txt'],
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _fileName = result.files.first.name);
    }
  }

  Future<void> _upload(BuildContext context) async {
    if (_fileName == null) return;
    setState(() => _loading = true);
    // Save metadata only (actual Firebase Storage upload would require
    // passing the File object; shown as metadata-only for hackathon scope)
    await widget.repo.addResourceMetadata(
      squadId: widget.squadId,
      fileName: _fileName!,
      storagePath: 'squads/${widget.squadId}/resources/$_fileName',
      subject: _subject,
      semester: _semester,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📦 File added to vault! +10 coins, +20 XP'),
          backgroundColor: Color(0xFF4C4D7B),
        ),
      );
      Navigator.pop(context);
    }
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      );
}
