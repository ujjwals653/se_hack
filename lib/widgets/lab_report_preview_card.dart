import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// ─────────────────────────────────────────────
//  DEMO CONFIG — swap these when real backend is ready
// ─────────────────────────────────────────────
const String _demoPdfUrl =
    'https://github.com/aneesh-afk/Java/raw/main/Exp_5(HomeWork)_D_B_2024300253.pdf';

const String _demoCommitSha = '809e15a';
const String _demoLabel     = 'Lab Report Draft v2';
// ─────────────────────────────────────────────

class LabReportPreviewCard extends StatefulWidget {
  /// repoName kept for API compatibility; ignored in demo mode
  final String repoName;
  const LabReportPreviewCard({required this.repoName, super.key});

  @override
  State<LabReportPreviewCard> createState() => _LabReportPreviewCardState();
}

class _LabReportPreviewCardState extends State<LabReportPreviewCard> {
  String? _localPath;

  @override
  Widget build(BuildContext context) {
    return _PreviewShell(
      header: _CompileHeader(
        commitSha: _demoCommitSha,
        label: _demoLabel,
        compiledAt: DateTime.now().subtract(const Duration(minutes: 3)),
        localPath: _localPath,
      ),
      child: _PDFLoader(
        pdfUrl: _demoPdfUrl,
        onPathReady: (path) => setState(() => _localPath = path),
      ),
    );
  }
}

// ── Downloads PDF once and hands it to PDFView ──────────────
class _PDFLoader extends StatefulWidget {
  final String pdfUrl;
  final ValueChanged<String>? onPathReady;
  const _PDFLoader({required this.pdfUrl, this.onPathReady});

  @override
  State<_PDFLoader> createState() => _PDFLoaderState();
}

class _PDFLoaderState extends State<_PDFLoader> {
  String? _localPath;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _downloadPdf();
  }

  @override
  void didUpdateWidget(_PDFLoader old) {
    super.didUpdateWidget(old);
    if (old.pdfUrl != widget.pdfUrl) _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');
      final dir  = await getTemporaryDirectory();
      final file = File('${dir.path}/lab_report_demo.pdf');
      await file.writeAsBytes(response.bodyBytes);
      if (mounted) {
        setState(() { _localPath = file.path; _loading = false; });
        widget.onPathReady?.call(file.path);
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4C4D7B)),
            SizedBox(height: 12),
            Text('Loading report…', style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      );
    }
    if (_error != null || _localPath == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
            const SizedBox(height: 8),
            Text('Could not load PDF', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(_error ?? 'Unknown error', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _downloadPdf,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4C4D7B), foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    return PDFView(
      filePath: _localPath!,
      enableSwipe: true,
      swipeHorizontal: false,
      autoSpacing: true,
      pageFling: true,
    );
  }
}

// ── Compile status header ────────────────────────────────────
class _CompileHeader extends StatelessWidget {
  final String commitSha;
  final String label;
  final DateTime compiledAt;
  final String? localPath;

  const _CompileHeader({
    required this.commitSha,
    required this.label,
    required this.compiledAt,
    this.localPath,
  });

  @override
  Widget build(BuildContext context) {
    final ago = _timeAgo(compiledAt);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Compiled $ago · $commitSha',
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: localPath == null ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullscreenPdfScreen(
                    localPath: localPath!,
                    title: label,
                    commitSha: commitSha,
                  ),
                ),
              );
            },
            child: Icon(
              Icons.open_in_new,
              size: 18,
              color: localPath == null ? Colors.grey.shade300 : const Color(0xFF4C4D7B),
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ── Outer card shell ────────────────────────────────────────
class _PreviewShell extends StatelessWidget {
  final Widget child;
  final Widget? header;
  const _PreviewShell({required this.child, this.header});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Row(
              children: [
                const Icon(Icons.article_outlined, size: 18, color: Color(0xFF4C4D7B)),
                const SizedBox(width: 8),
                Text(
                  'Lab Report Preview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (header != null) header!,
          const Divider(height: 1),
          SizedBox(height: 400, child: child),
        ],
      ),
    );
  }
}

// ── Full-screen PDF viewer ───────────────────────────────────
class FullscreenPdfScreen extends StatefulWidget {
  final String localPath;
  final String title;
  final String commitSha;

  const FullscreenPdfScreen({
    required this.localPath,
    required this.title,
    required this.commitSha,
    super.key,
  });

  @override
  State<FullscreenPdfScreen> createState() => _FullscreenPdfScreenState();
}

class _FullscreenPdfScreenState extends State<FullscreenPdfScreen> {
  int _currentPage = 0;
  int _totalPages  = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E2E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4C4D7B),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            Text('commit ${widget.commitSha}',
                style: const TextStyle(fontSize: 11, color: Colors.white60)),
          ],
        ),
        actions: [
          if (_totalPages > 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text('${_currentPage + 1} / $_totalPages',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            ),
        ],
      ),
      body: PDFView(
        filePath: widget.localPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        onPageChanged: (page, total) {
          if (mounted) setState(() {
            _currentPage = page ?? 0;
            _totalPages  = total ?? 0;
          });
        },
        onRender: (pages) {
          if (mounted) setState(() => _totalPages = pages ?? 0);
        },
      ),
    );
  }
}
