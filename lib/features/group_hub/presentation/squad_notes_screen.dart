import 'package:flutter/material.dart';
import 'package:se_hack/core/services/theme_service.dart';
import '../data/squad_repository.dart';
import '../models/notes_page_model.dart';
import 'package:intl/intl.dart';

class SquadNotesScreen extends StatelessWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  const SquadNotesScreen(
      {super.key,
      required this.squadId,
      required this.uid,
      required this.repo});

  static const Color _primary = Color(0xFF4C4D7B);

  static const _subjects = ['All', 'DSA', 'DBMS', 'OS', 'Maths', 'CN', 'Other'];

  @override
  Widget build(BuildContext context) {
    return _NotesListView(squadId: squadId, uid: uid, repo: repo, subjects: _subjects);
  }
}

class _NotesListView extends StatefulWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  final List<String> subjects;
  const _NotesListView(
      {required this.squadId,
      required this.uid,
      required this.repo,
      required this.subjects});

  @override
  State<_NotesListView> createState() => _NotesListViewState();
}

class _NotesListViewState extends State<_NotesListView> {
  static const Color _primary = Color(0xFF4C4D7B);
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('📝 Notes Wiki',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openEditor(context, null),
          ),
        ],
      ),
      body: Column(
        children: [
          // Subject filter chips
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: widget.subjects.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final s = widget.subjects[i];
                final selected = _filter == s;
                return GestureDetector(
                  onTap: () => setState(() => _filter = s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: selected ? _primary : context.surfaceBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<NotesPage>>(
              stream: widget.repo.watchNotes(widget.squadId),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF7B61FF)));
                }
                final pages = snap.data!
                    .where((p) =>
                        _filter == 'All' || p.subject == _filter)
                    .toList();

                if (pages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📝', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          _filter == 'All'
                              ? 'No notes yet — start the wiki!'
                              : 'No notes for $_filter yet',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 15),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => _openEditor(context, null),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Create First Page'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: pages.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final page = pages[i];
                    return _NotesListTile(
                      page: page,
                      onTap: () => _openEditor(context, page),
                      onDelete: () =>
                          widget.repo.deletePage(widget.squadId, page.id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, NotesPage? existing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _NotesEditorScreen(
          squadId: widget.squadId,
          uid: widget.uid,
          repo: widget.repo,
          existing: existing,
          subjects: widget.subjects.where((s) => s != 'All').toList(),
        ),
      ),
    );
  }
}

class _NotesListTile extends StatelessWidget {
  final NotesPage page;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  static const Color _primary = Color(0xFF4C4D7B);

  const _NotesListTile(
      {required this.page, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('📄', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    page.title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: context.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (page.subject.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            page.subject,
                            style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF4C4D7B),
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        '${page.lastEditedByName ?? 'Member'} · ${DateFormat('d MMM').format(page.lastEditedAt)}',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, size: 18, color: Colors.grey),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Editor Screen ────────────────────────────────────────────────────────────
class _NotesEditorScreen extends StatefulWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  final NotesPage? existing;
  final List<String> subjects;

  const _NotesEditorScreen({
    required this.squadId,
    required this.uid,
    required this.repo,
    this.existing,
    required this.subjects,
  });

  @override
  State<_NotesEditorScreen> createState() => _NotesEditorScreenState();
}

class _NotesEditorScreenState extends State<_NotesEditorScreen> {
  static const Color _primary = Color(0xFF4C4D7B);
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  String _subject = '';
  bool _preview = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.existing?.title ?? '');
    _contentCtrl =
        TextEditingController(text: widget.existing?.content ?? '');
    _subject = widget.existing?.subject ?? '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final page = NotesPage(
      id: widget.existing?.id ?? '',
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text,
      subject: _subject,
      lastEditedAt: DateTime.now(),
    );
    await widget.repo.savePage(widget.squadId, page);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('💾 Saved!'),
            backgroundColor: Color(0xFF4C4D7B)),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        foregroundColor: context.textPrimary,
        elevation: 0,
        title: TextField(
          controller: _titleCtrl,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold),
          decoration: const InputDecoration(
            hintText: 'Page title...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          // Subject picker
          DropdownButton<String>(
            value: _subject.isEmpty ? null : _subject,
            hint: const Text('Subject', style: TextStyle(fontSize: 12)),
            underline: const SizedBox(),
            items: widget.subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => setState(() => _subject = v ?? ''),
          ),
          const SizedBox(width: 4),
          // Preview toggle
          IconButton(
            icon: Icon(_preview ? Icons.edit : Icons.preview_outlined,
                color: _primary),
            onPressed: () => setState(() => _preview = !_preview),
          ),
          // Save
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child:
                        CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined, color: Color(0xFF4C4D7B)),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _preview
            ? SingleChildScrollView(
                child: Text(
                  _contentCtrl.text.isEmpty
                      ? 'Nothing to preview...'
                      : _contentCtrl.text,
                  style: const TextStyle(fontSize: 15, height: 1.6),
                ),
              )
            : TextField(
                controller: _contentCtrl,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontSize: 14, height: 1.6),
                decoration: const InputDecoration(
                  hintText:
                      'Start writing in Markdown...\n\n# Heading\n**bold**, *italic*, `code`',
                  border: InputBorder.none,
                ),
              ),
      ),
    );
  }
}
