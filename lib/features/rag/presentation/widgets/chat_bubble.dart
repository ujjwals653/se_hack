import 'package:flutter/material.dart';
import 'package:se_hack/features/rag/presentation/rag_bloc.dart';

/// A single chat bubble — styled differently for user vs. bot messages.
class ChatBubble extends StatelessWidget {
  final RagMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) _buildAvatar(),
          if (!message.isUser) const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                          )
                        : null,
                    color: message.isUser ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft:
                          Radius.circular(message.isUser ? 18 : 4),
                      bottomRight:
                          Radius.circular(message.isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: message.isUser ? Colors.white : const Color(0xFF1F2937),
                      height: 1.45,
                    ),
                  ),
                ),
                if (message.sources.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    children: message.sources
                        .map((s) => _SourceChip(source: s))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          if (message.isUser) const SizedBox(width: 8),
          if (message.isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
      );

  Widget _buildUserAvatar() => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.person, color: Color(0xFF6B7280), size: 18),
      );
}

class _SourceChip extends StatelessWidget {
  final String source;
  const _SourceChip({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE9FE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.description_outlined, size: 11, color: Color(0xFF7C3AED)),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              source,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF7C3AED),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
