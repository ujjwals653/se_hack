import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:se_hack/features/rag/data/models/rag_document.dart';
import 'package:se_hack/features/rag/presentation/rag_bloc.dart';
import 'package:se_hack/features/rag/presentation/pdf_viewer_screen.dart';
import 'package:se_hack/features/rag/presentation/image_viewer_screen.dart';

/// Horizontally scrollable row of indexed document chips.
class DocumentChipRow extends StatelessWidget {
  final List<RagDocument> documents;

  const DocumentChipRow({super.key, required this.documents});

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(
          'No documents yet — tap + to upload notes or a PDF',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      );
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: documents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final doc = documents[index];
          return _DocumentChip(doc: doc);
        },
      ),
    );
  }
}

class _DocumentChip extends StatelessWidget {
  final RagDocument doc;
  const _DocumentChip({required this.doc});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (doc.localPath.isNotEmpty) {
          final name = doc.name.toLowerCase();
          if (name.endsWith('.pdf')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PdfViewerScreen(
                  localPath: doc.localPath,
                  title: doc.name,
                ),
              ),
            );
          } else if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png')) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ImageViewerScreen(
                  localPath: doc.localPath,
                  title: doc.name,
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('This document was uploaded before offline viewing was supported.'),
              backgroundColor: Colors.orange.shade400,
            ),
          );
        }
      },
      onLongPress: () => _confirmDelete(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE9FE),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC4B5FD), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined,
                size: 14, color: Color(0xFF7C3AED)),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 120),
              child: Text(
                doc.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5B21B6),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${doc.chunkCount}c',
              style: const TextStyle(fontSize: 10, color: Color(0xFF7C3AED)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Document'),
        content: Text('Remove "${doc.name}" from the knowledge base?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<RagBloc>().add(RagDeleteDocument(doc.id));
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
