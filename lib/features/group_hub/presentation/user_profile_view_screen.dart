import 'package:flutter/material.dart';
import 'package:se_hack/core/services/theme_service.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/models/user_profile_model.dart';
import '../../friends/data/friends_repository.dart';
import '../../friends/models/friend_model.dart';
import 'friend_chat_screen.dart';

class UserProfileViewScreen extends StatefulWidget {
  final String uid;

  const UserProfileViewScreen({super.key, required this.uid});

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  static const Color _primary = Color(0xFF4C4D7B);
  static const Color _accent = Color(0xFF7B61FF);

  final _profileRepo = ProfileRepository();
  final _friendsRepo = FriendsRepository();

  Color _getStatusColor(UserStatus status) {
    switch (status) {
      case UserStatus.online:
        return Colors.greenAccent;
      case UserStatus.idle:
        return Colors.amber;
      case UserStatus.invisible:
        return Colors.grey;
    }
  }

  void _sendFriendRequest() async {
    await _friendsRepo.sendFriendRequest(widget.uid);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request sent!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        foregroundColor: context.textPrimary,
      ),
      body: StreamBuilder<UserProfile>(
        stream: _profileRepo.watchProfile(widget.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData) {
            return const Center(child: Text("User not found"));
          }
          final profile = snap.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Avatar with status
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: _primary.withOpacity(0.1),
                      backgroundImage: profile.photoUrl != null
                          ? NetworkImage(profile.photoUrl!)
                          : null,
                      child: profile.photoUrl == null
                          ? Text(
                              profile.displayName[0],
                              style: const TextStyle(fontSize: 40),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _getStatusColor(profile.status),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile.bio,
                  style: TextStyle(fontSize: 14, color: context.textSecondary),
                ),
                const SizedBox(height: 24),
                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatColumn(
                      label: 'Points',
                      value: profile.points.toString(),
                      icon: '🔥',
                    ),
                    _StatColumn(
                      label: 'Friends',
                      value: profile.friendsCount.toString(),
                      icon: '👥',
                    ),
                    _StatColumn(
                      label: 'Squads',
                      value: profile.squadIds.length.toString(),
                      icon: '⚔️',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Action buttons
                StreamBuilder<bool>(
                  stream: _friendsRepo.isFriend(widget.uid),
                  builder: (context, friendSnap) {
                    final isFriend = friendSnap.data ?? false;

                    return StreamBuilder<bool>(
                      stream: _friendsRepo.watchHasPendingRequest(widget.uid),
                      builder: (context, reqSnap) {
                        final hasPendingRequest = reqSnap.data ?? false;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: isFriend
                                    ? OutlinedButton(
                                        onPressed: () async {
                                          await _friendsRepo.unfriend(widget.uid);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Unfriended')),
                                            );
                                          }
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.redAccent),
                                        ),
                                        child: const Text('Unfriend'),
                                      )
                                    : hasPendingRequest
                                        ? ElevatedButton(
                                            onPressed: null, // Disabled
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.grey.shade300,
                                              disabledBackgroundColor: Colors.grey.shade300,
                                              disabledForegroundColor: Colors.grey.shade700,
                                              elevation: 0,
                                            ),
                                            child: const Text('Request Sent'),
                                          )
                                        : ElevatedButton(
                                            onPressed: _sendFriendRequest,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _accent,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('Add Friend'),
                                          ),
                              ),
                              const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (isFriend) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FriendChatScreen(
                                        friend: Friend(
                                          uid: profile.uid,
                                          displayName: profile.displayName,
                                          photoUrl: profile.photoUrl,
                                          status: profile.status,
                                          joinedAt: DateTime.now(),
                                        ),
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('You can only message friends.'),
                                    ),
                                  );
                                }
                              },
                              style: isFriend
                                  ? ElevatedButton.styleFrom(
                                      backgroundColor: _primary,
                                      foregroundColor: Colors.white,
                                    )
                                  : ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade300,
                                      foregroundColor: Colors.grey.shade700,
                                      elevation: 0,
                                    ),
                              child: const Text('Message'),
                            ),
                          ),
                        ],
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Badges Section
                if (profile.badges.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Badges',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: profile.badges.length,
                      itemBuilder: (ctx, i) {
                        return Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0C0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🏆', style: TextStyle(fontSize: 28)),
                              const SizedBox(height: 4),
                              Text(
                                profile.badges[i],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 100), // padding bottom
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}
