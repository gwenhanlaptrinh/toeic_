// File: lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../auth/login_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../plus/upgrade_plus_screen.dart'; 

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
        final int completedLessonsCount =
            (data['completedLessons'] as List?)?.length ?? 0;
        final int dailyXpEarned = data['dailyXpEarned'] ?? 0;
        final bool isPlus = data['isPlus'] ?? false; // Trạng thái tài khoản Plus

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
                const SizedBox(height: 20),
                
                // 👑 TRANG TRÍ AVATAR ĐA TẦNG SIÊU ĐẸP CHO TÀI KHOẢN PREMIUM PLUS (ĐÃ XÓA CÂY BÚT)
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isPlus ? 4 : 0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isPlus
                              ? LinearGradient(
                                  colors: [
                                    Colors.amber.shade800,
                                    Colors.yellow.shade400,
                                    Colors.orange.shade800,
                                    Colors.amber.shade600,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          boxShadow: isPlus
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.withOpacity(0.5),
                                    blurRadius: 18,
                                    spreadRadius: 4,
                                  )
                                ]
                              : null,
                        ),
                        child: Container(
                          padding: EdgeInsets.all(isPlus ? 3 : 0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPlus ? Colors.white : Colors.transparent,
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: isPlus ? Colors.amber.shade50 : Colors.blue.shade100,
                            child: Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : "U",
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: isPlus ? Colors.amber.shade900 : Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (isPlus)
                        Positioned(
                          top: -16,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                )
                              ],
                            ),
                            child: Icon(
                              Icons.workspace_premium,
                              color: Colors.amber.shade700,
                              size: 26,
                            ),
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

                // Truyền thêm uid vào để kiểm tra trạng thái thanh toán
                _buildPremiumBanner(context, isPlus, user.uid),
                const SizedBox(height: 24),

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

  // 👑 ĐÃ SỬA: Lắng nghe trạng thái Giao dịch nếu chưa phải PLUS
  Widget _buildPremiumBanner(BuildContext context, bool isPlus, String uid) {
    if (isPlus) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.amber.shade600, Colors.orange.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.shade300.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.workspace_premium, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TÀI KHOẢN PLUS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Đã mở khóa mọi bài học cao cấp ✨',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Nếu CHƯA là PLUS -> Kiểm tra xem có đang gửi yêu cầu thanh toán không
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('payment_requests')
          .where('uid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        // Đang quét dữ liệu thì ẩn nhẹ đi
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 80);
        }

        final isPending = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        // CÓ YÊU CẦU ĐANG CHỜ DUYỆT
        if (isPending) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.shade200.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Đang Chờ Xử Lý PLUS...',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Admin đang kiểm tra giao dịch của bạn ⏳',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // KHÔNG CÓ YÊU CẦU NÀO ĐANG CHỜ -> Hiện bảng Nâng cấp bình thường
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UpgradePlusScreen()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo.shade900, Colors.blue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nâng Cấp PLUS Ngay!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Mở khóa trọn bộ bài học & Đột phá TOEIC 👑',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatisticsChart(Map<String, dynamic> weeklyXp, int dailyXpEarned) {
    List<String> weekdays = ["", "T2", "T3", "T4", "T5", "T6", "T7", "CN"];
    
    // Lấy ra index của ngày hôm nay (T2 = 1, T3 = 2, ..., CN = 7)
    int currentWeekdayIndex = DateTime.now().weekday; 
    String todayStr = weekdays[currentWeekdayIndex];

    final List<Map<String, dynamic>> weeklyData = [];

    // 👑 LOGIC LỌC BÓNG MA TUẦN CŨ (TIME MASK)
    for (int i = 1; i <= 7; i++) {
      String dayKey = weekdays[i];
      int xp = 0;

      if (i < currentWeekdayIndex) {
        // Các ngày ĐÃ QUA trong tuần này -> Lấy từ database bình thường
        xp = weeklyXp[dayKey] ?? 0;
      } else if (i == currentWeekdayIndex) {
        // HÔM NAY -> Ưu tiên lấy điểm realtime mới nhất (Tránh việc Firebase chậm đồng bộ)
        int fbXp = weeklyXp[dayKey] ?? 0;
        xp = fbXp > dailyXpEarned ? fbXp : dailyXpEarned;
      } else {
        // CÁC NGÀY CHƯA TỚI (Tương lai) -> Chắc chắn phải là 0 (Ép về 0 để xóa sạch data rác tuần trước)
        xp = 0; 
      }

      weeklyData.add({'day': dayKey, 'xp': xp});
    }

    // Tìm giá trị XP cao nhất để chia tỷ lệ chiều cao cột (Tối thiểu là 100 để cột không quá cao khi điểm thấp)
    int maxCurrentXp = weeklyData.map((e) => e['xp'] as int).reduce((a, b) => a > b ? a : b);
    if (maxCurrentXp < 100) maxCurrentXp = 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Thống kê tuần này',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: weeklyData.map((data) {
              final int xp = data['xp'];
              final double columnHeight = xp > 0 ? (xp / maxCurrentXp) * 120 : 6;
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
                    height: columnHeight.clamp(6.0, 120.0), // Chiều cao tối thiểu 6px để luôn thấy được chân cột
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

  Widget _buildStatItem(IconData icon, Color color, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMenuSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
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