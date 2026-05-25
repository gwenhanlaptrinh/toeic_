// File: lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_provider.dart';
import '../courses/courses_screen.dart';
import '../review/review_screen.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../dictionary/dictionary_screen.dart';
import '../../widgets/word_of_day_card.dart';
import '../games/word_scramble_game.dart';
import '../games/word_match_game.dart';
import '../community/community_screen.dart';
import '../admin/admin_dashboard_screen.dart'; // ĐÃ IMPORT: Màn hình quản trị cho Admin
import '../../services/notification_service.dart'; // 👑 THÊM IMPORT SERVICE THÔNG BÁO

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // 👑 BIẾN CỜ: Để đảm bảo thông báo chỉ kêu 1 lần duy nhất lúc vừa vào trang chủ
  bool _hasShownWelcome = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<UserProvider>().checkDailyReset();
      await context.read<UserProvider>().loadWrongWords();
    });
  }

  Widget _gameCard(
    BuildContext context, {
    required String title,
    required String desc,
    required String emoji,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 15,
              ),
            ),
            Text(
              desc,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '+50 XP',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Đồng bộ luồng dữ liệu tài khoản theo thời gian thực
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String role = data['role'] ?? 'user';
        final String userName = data['name'] ?? "Học viên";

        // 👑 GỌI THÔNG BÁO CHÀO MỪNG NGAY LẬP TỨC (NẾU CHƯA GỌI)
        if (!_hasShownWelcome) {
          _hasShownWelcome = true;
          NotificationService().showWelcomeNotification(userName);
        }

        // 1/ TRANG ADMIN GIỜ CHỈ CÒN TRANG QUẢN TRỊ KHÔNG CÒN THANH ĐIỀU HƯỚNG USER NỮA
        if (role == 'admin') {
          return const AdminDashboardScreen();
        }

        // Nếu là User thường thì hiển thị giao diện học tập như cũ
        final List<Widget> screens = [
          _buildDashboardView(context, data),
          const CoursesScreen(),
          const ReviewScreen(),
          const LibraryScreen(),
          const ProfileScreen(),
        ];

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: screens),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Khóa học',
              ),
              NavigationDestination(
                icon: Icon(Icons.replay_circle_filled_outlined),
                selectedIcon: Icon(Icons.replay_circle_filled),
                label: 'Ôn tập',
              ),
              NavigationDestination(
                icon: Icon(Icons.bookmarks_outlined),
                selectedIcon: Icon(Icons.bookmarks),
                label: 'Thư viện',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Hồ sơ',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardView(BuildContext context, Map<String, dynamic> data) {
    final wrongWords = Provider.of<UserProvider>(context).wrongWords;

    final String name = data['name'] ?? "Học viên";
    final int streak = data['streak'] ?? 0;
    final int dailyLessonsCompleted = data['dailyLessonsCompleted'] ?? 0;
    final int dailyXpEarned = data['dailyXpEarned'] ?? 0;
    final bool isMission1Claimed = data['rewardMission1Claimed'] ?? false;
    final bool isMission2Claimed = data['rewardMission2Claimed'] ?? false;
    final bool isPlus = data['isPlus'] ?? false; // Lấy trạng thái Plus

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER: Chào mừng & Streak
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chào mừng trở lại,',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // 👑 2/ NẾU LÀ PLUS THÌ Ở HOME HIỂN THỊ HUY HIỆU PLUS XỊN XÒ
                            if (isPlus) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.amber, Colors.orangeAccent],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium, color: Colors.white, size: 12),
                                    SizedBox(width: 2),
                                    Text(
                                      'PLUS',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.forum_rounded,
                          color: Colors.blue,
                          size: 28,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CommunityScreen(),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 28,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LeaderboardScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              color: Colors.orange,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$streak ngày',
                              style: const TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DictionaryScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.search, color: Colors.blue),
                      SizedBox(width: 12),
                      Text(
                        'Tra cứu từ vựng tiếng Anh...',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                '📅 Từ của ngày hôm nay',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const WordOfDayCard(),
              const SizedBox(height: 24),

              const Text(
                '🎮 Mini Games',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _gameCard(
                      context,
                      title: 'Word Scramble',
                      desc: 'Sắp xếp chữ cái',
                      emoji: '🔤',
                      color: const Color(0xFF1565C0),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WordScrambleGame(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _gameCard(
                      context,
                      title: 'Word Match',
                      desc: 'Nối từ với nghĩa',
                      emoji: '🎯',
                      color: Colors.orange[700]!,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WordMatchGame(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Nhiệm vụ hôm nay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              _buildMissionCard(
                icon: Icons.school,
                iconColor: Colors.green,
                title: 'Hoàn thành bài học mới',
                subtitle: 'Vượt qua bài kiểm tra để nhận thưởng.',
                progress: dailyLessonsCompleted >= 1 ? 1.0 : 0.0,
                progressText: '$dailyLessonsCompleted/1 bài',
                isClaimed: isMission1Claimed,
                rewardText: '+50 XP',
              ),
              const SizedBox(height: 12),

              _buildMissionCard(
                icon: Icons.stars_rounded,
                iconColor: Colors.blue,
                title: 'Kiếm được 200 XP hôm nay',
                subtitle: 'Tích lũy năng nổ để nhận thêm thưởng.',
                progress: (dailyXpEarned / 200).clamp(0.0, 1.0),
                progressText: '$dailyXpEarned/200 XP',
                isClaimed: isMission2Claimed,
                rewardText: '+100 XP',
              ),

              if (wrongWords.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Đến hạn ôn tập!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Bạn có ${wrongWords.length} từ vựng cần ôn tập lại ngay.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(
                          () => _currentIndex = 2,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Ôn ngay'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMissionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double progress,
    required String progressText,
    required bool isClaimed,
    required String rewardText,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          isClaimed
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'Đã nhận $rewardText',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                )
              : Text(
                  progressText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
        ],
      ),
    );
  }
}