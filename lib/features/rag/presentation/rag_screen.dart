import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:se_hack/features/rag/domain/rag_service.dart';
import 'package:se_hack/features/rag/data/rag_repository.dart';
import 'package:se_hack/features/rag/presentation/rag_bloc.dart';
import 'package:se_hack/features/rag/presentation/widgets/chat_bubble.dart';
import 'package:se_hack/features/rag/presentation/widgets/document_chip.dart';
import 'package:se_hack/features/rag/presentation/widgets/upload_sheet.dart';

class RagScreen extends StatelessWidget {
  const RagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => RagBloc(RagService(repo: RagRepository()))
        ..add(RagLoadDocuments()),
      child: const _RagScreenBody(),
    );
  }
}

class _RagScreenBody extends StatefulWidget {
  const _RagScreenBody();

  @override
  State<_RagScreenBody> createState() => _RagScreenBodyState();
}

class _RagScreenBodyState extends State<_RagScreenBody> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendQuestion() {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    _controller.clear();
    context.read<RagBloc>().add(RagAskQuestion(q));
    Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F4FF),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: BlocConsumer<RagBloc, RagState>(
              listener: (context, state) {
                if (state is RagError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red.shade400,
                    ),
                  );
                }
                // Scroll to bottom on new message
                if (state.messages.isNotEmpty) {
                  Future.delayed(
                      const Duration(milliseconds: 100), _scrollToBottom);
                }
              },
              builder: (context, state) {
                return Column(
                  children: [
                    // Document chips row
                    const SizedBox(height: 8),
                    DocumentChipRow(documents: state.documents),
                    const SizedBox(height: 4),

                    // Ingest progress bar
                    if (state is RagIngesting) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Indexing "${state.fileName}"… ${state.done}/${state.total} chunks',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF7C3AED)),
                            ),
                            const SizedBox(height: 4),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: state.progress == 0 ? null : state.progress,
                                minHeight: 5,
                                backgroundColor: const Color(0xFFEDE9FE),
                                valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Divider(height: 1),

                    // Chat messages
                    Expanded(
                      child: state.messages.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(top: 12, bottom: 16),
                              itemCount: state.messages.length +
                                  (state is RagAnswering ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == state.messages.length) {
                                  return _buildTypingIndicator();
                                }
                                return ChatBubble(message: state.messages[index]);
                              },
                            ),
                    ),

                    // Input bar
                    _buildInputBar(context, state),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Study AI',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                Text('Ask anything from your notes',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          BlocBuilder<RagBloc, RagState>(
            builder: (context, state) => GestureDetector(
              onTap: () => UploadSheet.show(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('Study AI Ready',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Text(
            'Upload your notes or PDF, then ask\nanything — I\'ll answer from your content.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
          ),
          const SizedBox(height: 28),
          _SuggestionChip(
              text: '📖 Summarise my uploaded notes',
              onTap: () => _askSuggestion('Summarise the key points from my uploaded notes')),
          const SizedBox(height: 8),
          _SuggestionChip(
              text: '❓ What are the main topics covered?',
              onTap: () => _askSuggestion('What are the main topics covered in my uploaded documents?')),
          const SizedBox(height: 8),
          _SuggestionChip(
              text: '📝 Give me 5 exam questions',
              onTap: () => _askSuggestion('Generate 5 exam-style questions from my notes')),
        ],
      ),
    );
  }

  void _askSuggestion(String q) {
    context.read<RagBloc>().add(RagAskQuestion(q));
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _Dot(delay: 0),
                _Dot(delay: 200),
                _Dot(delay: 400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, RagState state) {
    final busy = state is RagIngesting || state is RagAnswering;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 12, offset: Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !busy,
              onSubmitted: (_) => _sendQuestion(),
              decoration: InputDecoration(
                hintText: busy ? 'Processing…' : 'Ask a question from your notes…',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF5F4FF),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: busy ? null : _sendQuestion,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: busy
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)]),
                color: busy ? Colors.grey.shade200 : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                busy ? Icons.hourglass_empty : Icons.send_rounded,
                color: busy ? Colors.grey.shade400 : Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Suggestion chip on empty state
class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _SuggestionChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFC4B5FD)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
          ],
        ),
        child: Text(text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF5B21B6))),
      ),
    );
  }
}

// Animated typing dot
class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: -6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          width: 7,
          height: 7,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
