import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreBadge {
  final String id;
  final String title;
  final String emoji;
  final int cost;
  final Color color;

  const StoreBadge(this.id, this.title, this.emoji, this.cost, this.color);
}

const List<StoreBadge> _catalog = [
  StoreBadge('badge_early_bird', 'Early Bird', '🌅', 50, Color(0xFFC0E8F8)),
  StoreBadge('badge_night_owl', 'Night Owl', '🦉', 75, Color(0xFFD0D0FF)),
  StoreBadge('badge_focus_master', 'Focus Master', '🧘‍♂️', 100, Color(0xFFD0F0C0)),
  StoreBadge('badge_1_percent', 'Top 1%', '💎', 250, Color(0xFFFFD0E0)),
  StoreBadge('badge_grinder', 'Grinder', '⚙️', 500, Color(0xFFFFF0C0)),
  StoreBadge('badge_scholar', 'Scholar', '🎓', 1000, Color(0xFFEDE9FE)),
];

class BadgeStoreScreen extends StatelessWidget {
  final String uid;

  const BadgeStoreScreen({super.key, required this.uid});

  Future<void> _purchaseBadge(BuildContext context, StoreBadge badge, int currentPoints) async {
    if (currentPoints < badge.cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not enough points to unlock ${badge.title}. Keep focusing!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      await userRef.update({
        'points': FieldValue.increment(-badge.cost),
        'focusPoints': FieldValue.increment(-badge.cost),
        'badges': FieldValue.arrayUnion(['${badge.emoji} ${badge.title}']),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully purchased ${badge.title}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error purchasing badge: \$e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
        title: const Text(
          'Badge Shop',
          style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          // Fallback through multiple point variables to ensure we fetch correctly
          final currentPoints = (data['focusPoints'] as num?)?.toInt() ?? (data['points'] as num?)?.toInt() ?? 0;
          final ownedBadgesList = List<String>.from(data['badges'] ?? []);

          return Column(
            children: [
              // Header displaying current balance
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Your Balance',
                      style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.stars_rounded, color: Color(0xFF38BDF8), size: 36),
                        const SizedBox(width: 8),
                        TweenAnimationBuilder<int>(
                          duration: const Duration(seconds: 1),
                          tween: IntTween(begin: 0, end: currentPoints),
                          builder: (context, value, child) {
                            return Text(
                              value.toString(),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4C4D7B),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Grid View
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _catalog.length,
                  itemBuilder: (context, index) {
                    final badge = _catalog[index];
                    final isOwned = ownedBadgesList.contains('${badge.emoji} ${badge.title}');
                    final isAffordable = currentPoints >= badge.cost;

                    return _buildBadgeCard(context, badge, isOwned, isAffordable, currentPoints);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadgeCard(
    BuildContext context,
    StoreBadge badge,
    bool isOwned,
    bool isAffordable,
    int currentPoints,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwned
              ? Colors.green.shade300
              : isAffordable
                  ? badge.color
                  : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: badge.color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: badge.color.withOpacity(isOwned ? 1.0 : 0.5),
              shape: BoxShape.circle,
            ),
            child: Text(
              badge.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            badge.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF4C4D7B),
            ),
          ),
          const SizedBox(height: 8),
          if (isOwned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Owned',
                style: TextStyle(
                  color: Colors.green.shade800,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _purchaseBadge(context, badge, currentPoints),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isAffordable
                        ? [const Color(0xFF6C63FF), const Color(0xFF8B5CF6)]
                        : [Colors.grey.shade300, Colors.grey.shade400],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Buy for ${badge.cost}',
                      style: TextStyle(
                        color: isAffordable ? Colors.white : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.stars_rounded,
                      color: isAffordable ? const Color(0xFF38BDF8) : Colors.grey.shade500,
                      size: 14,
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
