import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:se_hack/features/rag/presentation/rag_bloc.dart';

/// Bottom sheet for picking and ingesting a PDF or image file.
class UploadSheet extends StatelessWidget {
  const UploadSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<RagBloc>(),
        child: const UploadSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Upload Study Material',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Supported: PDF, JPG, PNG',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _UploadOption(
                  icon: Icons.picture_as_pdf_outlined,
                  label: 'PDF',
                  color: const Color(0xFFFFEDE8),
                  iconColor: const Color(0xFFEA580C),
                  onTap: () => _pickAndIngest(context, isPdf: true),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _UploadOption(
                  icon: Icons.image_outlined,
                  label: 'Image / Notes',
                  color: const Color(0xFFEDE9FE),
                  iconColor: const Color(0xFF7C3AED),
                  onTap: () => _pickAndIngest(context, isPdf: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndIngest(BuildContext context, {required bool isPdf}) async {
    final result = await FilePicker.platform.pickFiles(
      type: isPdf ? FileType.custom : FileType.image,
      allowedExtensions: isPdf ? ['pdf'] : null,
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    if (!context.mounted) return;
    Navigator.pop(context);
    context.read<RagBloc>().add(RagIngestFile(file, isPdf: isPdf));
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  const _UploadOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: iconColor)),
          ],
        ),
      ),
    );
  }
}
