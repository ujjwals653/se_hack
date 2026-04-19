import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:se_hack/core/services/theme_service.dart';
import 'package:provider/provider.dart';
import '../domain/cognitive_debt_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final myUserId = context.read<FocusService>().userId;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4C4D7B),
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber),
            SizedBox(width: 8),
            Text('Study Squad Leaderboard'),
          ],
        ),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('focusPoints', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4C4D7B)),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No data yet. Start studying to be #1!',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final displayName = data['displayName'] ?? 'Anonymous';
              final points = data['focusPoints'] ?? 0;
              final isMe = doc.id == myUserId;
              final isTopThree = index < 3;

              Color rankColor = Colors.grey;
              IconData? medalIcon;
              if (index == 0) {
                rankColor = Colors.amber;
                medalIcon = Icons.emoji_events;
              } else if (index == 1) {
                rankColor = Colors.blueGrey.shade300;
                medalIcon = Icons.emoji_events;
              } else if (index == 2) {
                rankColor = Colors.brown.shade400;
                medalIcon = Icons.emoji_events;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isMe
                      ? const Color(0xFF4C4D7B).withOpacity(0.15)
                      : context.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isMe
                        ? const Color(0xFF4C4D7B)
                        : (isTopThree ? rankColor.withOpacity(0.4) : Colors.grey.shade200),
                    width: isMe ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    if (isMe)
                      BoxShadow(
                        color: const Color(0xFF4C4D7B).withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        child: Center(
                          child: isTopThree
                              ? Icon(medalIcon, color: rankColor, size: 24)
                              : Text(
                                  (index + 1).toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: isMe
                            ? const Color(0xFF4C4D7B)
                            : Colors.grey.shade100,
                        radius: 20,
                        child: Text(
                          displayName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.grey.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    isMe ? displayName + ' (You)' : displayName,
                    style: TextStyle(
                      fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                      fontSize: 15,
                      color: isMe ? const Color(0xFF4C4D7B) : Colors.black87,
                    ),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF4C4D7B)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: isMe ? Colors.amber : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          points.toString(),
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
