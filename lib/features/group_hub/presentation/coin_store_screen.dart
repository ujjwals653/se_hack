import 'package:flutter/material.dart';
import '../data/squad_repository.dart';

class CoinStoreScreen extends StatelessWidget {
  final String uid;
  final SquadRepository repo;
  const CoinStoreScreen({super.key, required this.uid, required this.repo});

  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);
  static const Color _gold = Color(0xFFFFAB00);

  static const _items = [
    _StoreItem('🎨', 'Squad Badge Upgrade', 'Unlock a premium badge for your squad', 200),
    _StoreItem('🔒', 'Bunk Pass', 'Skip 1 class without attendance penalty', 150),
    _StoreItem('📚', 'RAG Priority Boost', 'Faster PDF query processing slot', 100),
    _StoreItem('🏷️', 'Custom Role Title', 'Custom display name, e.g. "Caffeine Addict"', 80),
    _StoreItem('🎯', 'Exam Focus Boost', 'Double XP on focus sessions for 24h', 120),
    _StoreItem('📊', 'Weekly Wrap Pro', 'Detailed category breakdown in expense wrap', 50),
    _StoreItem('⏰', 'Focus Timer Skin', 'Aesthetic theme for the ContextSwitch timer', 60),
    _StoreItem('🧾', 'Bunk Shield (7-day)', 'Protects attendance for 7 days', 300),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _primary,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '🪙 Coin Store',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          StreamBuilder<int>(
            stream: repo.watchMyCoins(),
            builder: (_, snap) {
              final coins = snap.data ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.amber.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙',
                            style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 4),
                        Text(
                          '$coins',
                          style: const TextStyle(
                            color: Colors.amber,
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
          ),
        ],
      ),
      body: Column(
        children: [
          // Earn coins section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to earn coins',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: const [
                      _EarnChip('⏱️ 30min focus', '+10'),
                      _EarnChip('🎯 Daily goal', '+25'),
                      _EarnChip('🔥 7-day streak', '+100'),
                      _EarnChip('⚔️ War win', '+50'),
                      _EarnChip('✅ Kanban task', '+15'),
                      _EarnChip('🌅 First login', '+5'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // White area with store items
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final item = _items[i];
                  return _StoreTile(item: item, repo: repo, uid: uid);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EarnChip extends StatelessWidget {
  final String label;
  final String amount;
  const _EarnChip(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
                  const TextStyle(color: Colors.white, fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            amount,
            style: const TextStyle(
              color: Color(0xFFFFAB00),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _StoreTile extends StatefulWidget {
  final _StoreItem item;
  final SquadRepository repo;
  final String uid;
  const _StoreTile(
      {required this.item, required this.repo, required this.uid});

  @override
  State<_StoreTile> createState() => _StoreTileState();
}

class _StoreTileState extends State<_StoreTile> {
  bool _loading = false;
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _gold = Color(0xFFFFAB00);

  Future<void> _buy(BuildContext context) async {
    setState(() => _loading = true);
    final success =
        await widget.repo.spendCoins(widget.item.cost, widget.item.title);
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? '🎉 ${widget.item.title} purchased!'
              : '❌ Not enough coins! Earn more by studying.'),
          backgroundColor:
              success ? const Color(0xFF4C4D7B) : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(widget.item.emoji,
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.item.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _loading ? null : () => _buy(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              elevation: 0,
            ),
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black54),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪙',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 3),
                      Text(
                        '${widget.item.cost}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _StoreItem {
  final String emoji;
  final String title;
  final String description;
  final int cost;
  const _StoreItem(this.emoji, this.title, this.description, this.cost);
}
