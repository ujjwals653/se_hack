import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerScreen extends StatefulWidget {
  final String localPath;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.localPath,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfController _pdfController;
  bool _isFileExists = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  Future<void> _initPdf() async {
    final file = File(widget.localPath);
    if (await file.exists()) {
      _pdfController = PdfController(
        document: PdfDocument.openFile(widget.localPath),
      );
      setState(() {
        _isFileExists = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isFileExists = false;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    if (_isFileExists) {
      _pdfController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FF),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      );
    }
    if (!_isFileExists) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Document file not found locally.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'It may have been uploaded before offline support.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            )
          ],
        ),
      );
    }

    return PdfView(
      controller: _pdfController,
      scrollDirection: Axis.vertical,
      backgroundDecoration: const BoxDecoration(color: Color(0xFFF5F4FF)),
    );
  }
}
