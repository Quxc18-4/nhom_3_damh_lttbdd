import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'follow_button.dart';
import 'package:nhom_3_damh_lttbdd/screens/accountSettingScreen.dart';

import 'package:nhom_3_damh_lttbdd/screens/add_checkins/checkinScreen.dart';
import 'package:nhom_3_damh_lttbdd/model/post_model.dart';

class ProfileHeader extends StatelessWidget {
  final User user;
  final bool isMyProfile;
  final bool isFollowing;
  final bool isLoadingFollow;
  final int followersCount;
  final int followingCount;
  final int postCount;
  final VoidCallback onFollowToggle;
  final String currentUserId;

  const ProfileHeader({
    super.key,
    required this.user,
    required this.isMyProfile,
    required this.isFollowing,
    required this.followersCount,
    required this.followingCount,
    required this.postCount,
    required this.onFollowToggle,
    required this.isLoadingFollow,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.id).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final userName = userData['name'] ?? user.name;
        final avatarUrl = userData['avatarUrl'] ?? user.avatarUrl;

        final ImageProvider avatarProvider = avatarUrl.startsWith('http')
            ? NetworkImage(avatarUrl)
            : AssetImage(avatarUrl);

        return Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (isMyProfile)
                      IconButton(
                        icon: const Icon(Icons.settings_outlined),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  AccountSettingScreen(userId: currentUserId),
                            ),
                          );
                        },
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
              Row(
                children: [
                  CircleAvatar(radius: 40, backgroundImage: avatarProvider),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('$postCount', 'Bài viết'),
                        _buildStat('$followersCount', 'Người theo dõi'),
                        _buildStat('$followingCount', 'Đang theo dõi'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!isMyProfile)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    FollowButton(
                      isFollowing: isFollowing,
                      isLoading: isLoadingFollow,
                      onPressed: onFollowToggle,
                    ),
                  ],
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              if (isMyProfile)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 40),
                      ),
                      child: const Text('Chỉnh sửa Travel Map'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckinScreen(
                                    currentUserId: currentUserId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Viết bài'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckinScreen(
                                    currentUserId: currentUserId,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Check-in'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStat(String value, String label) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: Colors.grey)),
    ],
  );
}
