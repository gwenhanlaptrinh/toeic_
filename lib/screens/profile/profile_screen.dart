// File: lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String userName = data['name'] ?? "Học viên Chăm Chỉ";
        final String userEmail = data['email'] ?? "hocvien@example.com";
        final int streakDays = data['streak'] ?? 0;
        final int currentXP = data['xp'] ?? 0;

        final int wordsLearnedCount = data['wordsLearnedCount'] ?? 0;
        // Thêm trường Bài đã học bằng cách đếm độ dài của mảng
        final int completedLessonsCount =
            (data['completedLessons'] as List?)?.length ?? 0;

        // Lấy Tổng XP của ngày hôm nay (chắc chắn chính xác 100%)
        final int dailyXpEarned = data['dailyXpEarned'] ?? 0;

        final Map<String, dynamic> weeklyXpData =
            data['weeklyXp'] ??
            {'T2': 0, 'T3': 0, 'T4': 0, 'T5': 0, 'T6': 0, 'T7': 0, 'CN': 0};

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: AppBar(
            title: const Text(
              'Hồ Sơ Của Tôi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // BỔ SUNG: Chỉnh thành 4 cột thông số (Thêm Bài học)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade100,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        Icons.local_fire_department,
                        Colors.orange,
                        '$streakDays',
                        'Ngày học',
                      ),
                      _buildStatItem(
                        Icons.emoji_events,
                        Colors.amber,
                        '$currentXP',
                        'Tổng XP',
                      ),
                      _buildStatItem(
                        Icons.menu_book_rounded,
                        Colors.purple,
                        '$completedLessonsCount',
                        'Bài học',
                      ),
                      _buildStatItem(
                        Icons.g_translate_rounded,
                        Colors.blue,
                        '$wordsLearnedCount',
                        'Từ vựng',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Truyền dailyXpEarned vào để fix dứt điểm lỗi hiển thị sai của ngày hôm nay
                _buildStatisticsChart(weeklyXpData, dailyXpEarned),
                const SizedBox(height: 24),

                _buildMenuSection(
                  title: 'Cài đặt chung',
                  items: [
                    _buildMenuItem(
                      Icons.notifications_active_outlined,
                      'Nhắc nhở học tập',
                      true,
                    ),
                    _buildMenuItem(
                      Icons.dark_mode_outlined,
                      'Chế độ tối (Dark Mode)',
                      false,
                    ),
                    _buildMenuItem(
                      Icons.volume_up_outlined,
                      'Tự động phát âm thanh',
                      true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildMenuSection(
                  title: 'Khác',
                  items: [
                    _buildMenuItem(
                      Icons.help_outline,
                      'Hướng dẫn sử dụng',
                      null,
                    ),
                    _buildMenuItem(
                      Icons.info_outline,
                      'Thông tin ứng dụng',
                      null,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await context.read<AuthProvider>().signOut();
                        if (context.mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Lỗi đăng xuất: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Đăng xuất tài khoản',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsChart(
    Map<String, dynamic> weeklyXp,
    int dailyXpEarned,
  ) {
    // FIX ĐÚNG THỨ TRONG TUẦN
    List<String> weekdays = ["", "T2", "T3", "T4", "T5", "T6", "T7", "CN"];

    String todayStr = weekdays[DateTime.now().weekday];

    final List<Map<String, dynamic>> weeklyData = [
      {
        'day': 'T2',
        'xp': todayStr == 'T2' ? dailyXpEarned : (weeklyXp['T2'] ?? 0),
      },
      {
        'day': 'T3',
        'xp': todayStr == 'T3' ? dailyXpEarned : (weeklyXp['T3'] ?? 0),
      },
      {
        'day': 'T4',
        'xp': todayStr == 'T4' ? dailyXpEarned : (weeklyXp['T4'] ?? 0),
      },
      {
        'day': 'T5',
        'xp': todayStr == 'T5' ? dailyXpEarned : (weeklyXp['T5'] ?? 0),
      },
      {
        'day': 'T6',
        'xp': todayStr == 'T6' ? dailyXpEarned : (weeklyXp['T6'] ?? 0),
      },
      {
        'day': 'T7',
        'xp': todayStr == 'T7' ? dailyXpEarned : (weeklyXp['T7'] ?? 0),
      },
      {
        'day': 'CN',
        'xp': todayStr == 'CN' ? dailyXpEarned : (weeklyXp['CN'] ?? 0),
      },
    ];

    int maxCurrentXp = weeklyData
        .map((e) => e['xp'] as int)
        .reduce((a, b) => a > b ? a : b);

    if (maxCurrentXp < 100) {
      maxCurrentXp = 100;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Thống kê tuần này',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeklyData.map((data) {
              final int xp = data['xp'];

              final double columnHeight = xp > 0
                  ? (xp / maxCurrentXp) * 120
                  : 6;

              final bool isToday = data['day'] == todayStr;

              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$xp',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isToday ? Colors.blue : Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 6),

                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: columnHeight.clamp(6, 120),

                    decoration: BoxDecoration(
                      color: isToday ? Colors.blue : Colors.blue.shade100,

                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    data['day'],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,

                      color: isToday ? Colors.black87 : Colors.grey.shade600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    IconData icon,
    Color color,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 24,
        ), // Thu nhỏ size icon một chút để vừa vặn 4 cột
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ), // Giảm nhẹ size chữ
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuSection({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, bool? isToggle) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.blue, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      trailing: isToggle != null
          ? Switch(
              value: isToggle,
              onChanged: (val) {},
              activeColor: Colors.blue,
            )
          : const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: isToggle == null ? () {} : null,
    );
  }
}
