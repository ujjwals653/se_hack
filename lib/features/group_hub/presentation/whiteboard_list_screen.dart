import 'package:flutter/material.dart';
import 'package:se_hack/core/services/theme_service.dart';
import 'package:intl/intl.dart';
import '../data/squad_repository.dart';
import '../models/squad_model.dart';
import '../models/whiteboard_model.dart';
import 'whiteboard_screen.dart'; // will be the canvas screen

class WhiteboardListScreen extends StatefulWidget {
  final String squadId;
  final String uid;
  final SquadRepository repo;
  final SquadRole myRole;

  const WhiteboardListScreen({
    super.key,
    required this.squadId,
    required this.uid,
    required this.repo,
    required this.myRole,
  });

  @override
  State<WhiteboardListScreen> createState() => _WhiteboardListScreenState();
}

class _WhiteboardListScreenState extends State<WhiteboardListScreen> {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Whiteboard>>(
      stream: widget.repo.watchWhiteboards(widget.squadId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: _accent));
        }

        final whiteboards = snapshot.data!;

        return Scaffold(
          backgroundColor: context.scaffoldBg,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showCreateDialog,
            backgroundColor: _accent,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Whiteboard', style: TextStyle(color: Colors.white)),
          ),
          body: whiteboards.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.brush, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No whiteboards yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Collaborate on ideas visually',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: whiteboards.length,
                  itemBuilder: (context, index) {
                    final wb = whiteboards[index];
                    return _buildWhiteboardCard(wb);
                  },
                ),
        );
      },
    );
  }

  Widget _buildWhiteboardCard(Whiteboard wb) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WhiteboardScreen(
              squadId: widget.squadId,
              uid: widget.uid,
              repo: widget.repo,
              whiteboardId: wb.id,
              whiteboardName: wb.name,
              myRole: widget.myRole,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.04),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Icon(Icons.palette_outlined, size: 48, color: _accent.withOpacity(0.5)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          wb.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.myRole.canManageWhiteboard || wb.createdBy == widget.uid)
                        GestureDetector(
                          onTap: () => _showDeleteDialog(wb),
                          child: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade400),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Created ${DateFormat('MMM d, y').format(wb.createdAt)}',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showCreateDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Whiteboard'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Whiteboard Name',
            hintText: 'e.g., Mindmap',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              await widget.repo.createWhiteboard(widget.squadId, name);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white),
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Whiteboard wb) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Whiteboard?'),
        content: Text('Are you sure you want to delete "${wb.name}"? All drawings will be permanently lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await widget.repo.deleteWhiteboard(widget.squadId, wb.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
