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
// QUAN TRỌNG: Đừng quên import màn hình từ điển
import '../dictionary/dictionary_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
 @override
void initState() {
  super.initState();

  WidgetsBinding.instance
      .addPostFrameCallback((_) async {

    await context
        .read<UserProvider>()
        .checkDailyReset();

    await context
        .read<UserProvider>()
        .loadWrongWords();
  });
}

  // TỰ ĐỘNG RESET NHIỆM VỤ MỖI NGÀY & KIỂM TRA STREAK
  Future<void> _updateUserStreakAndResetDaily() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.userModel;
    if (user == null) return;

    final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    try {
      final docSnap = await userDocRef.get();
      if (!docSnap.exists) return;

      final data = docSnap.data();
      final String? lastActiveStr = data?['lastActiveDate'];
      int currentStreak = data?['streak'] ?? 0;

      Map<String, dynamic> updateData = {};

      if (data?['dailyXpEarned'] == null) updateData['dailyXpEarned'] = 0;
      if (data?['dailyLessonsCompleted'] == null) updateData['dailyLessonsCompleted'] = 0;
      if (data?['rewardMission1Claimed'] == null) updateData['rewardMission1Claimed'] = false;
      if (data?['rewardMission2Claimed'] == null) updateData['rewardMission2Claimed'] = false;
      if (data?['completedLessons'] == null) updateData['completedLessons'] = [];
      if (data?['wordsLearnedCount'] == null) updateData['wordsLearnedCount'] = 0;
      if (data?['weeklyXp'] == null) {
        updateData['weeklyXp'] = {'T2': 0, 'T3': 0, 'T4': 0, 'T5': 0, 'T6': 0, 'T7': 0, 'CN': 0};
      }

      if (lastActiveStr == null) {
        updateData['streak'] = 1;
        updateData['lastActiveDate'] = todayStr;
        await userDocRef.update(updateData);
        await authProvider.fetchUserData(user.uid);
      } else if (lastActiveStr != todayStr) {
        // HÀNH VI SANG NGÀY MỚI: Reset tiến trình nhiệm vụ
        updateData['lastActiveDate'] = todayStr;
        updateData['dailyXpEarned'] = 0;
        updateData['dailyLessonsCompleted'] = 0;
        updateData['rewardMission1Claimed'] = false;
        updateData['rewardMission2Claimed'] = false;

        // Nếu sang đầu tuần mới thì reset biểu đồ tuần
        if (now.weekday == 1) {
          updateData['weeklyXp'] = {'T2': 0, 'T3': 0, 'T4': 0, 'T5': 0, 'T6': 0, 'T7': 0, 'CN': 0};
        }

        final lastActiveDate = DateTime.parse(lastActiveStr);
        final todayDate = DateTime.parse(todayStr);
        final difference = todayDate.difference(lastActiveDate).inDays;

        if (difference == 1) {
          updateData['streak'] = currentStreak + 1;
        } else if (difference > 1) {
          updateData['streak'] = 1; 
        }
        await userDocRef.update(updateData);
        await authProvider.fetchUserData(user.uid);
      } else {
        if (updateData.isNotEmpty) await userDocRef.update(updateData);
      }
    } catch (e) {
      debugPrint("Lỗi đồng bộ ngày mới: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _buildDashboardView(context),
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
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Trang chủ'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Khóa học'),
          NavigationDestination(icon: Icon(Icons.replay_circle_filled_outlined), selectedIcon: Icon(Icons.replay_circle_filled), label: 'Ôn tập'),
          NavigationDestination(icon: Icon(Icons.bookmarks_outlined), selectedIcon: Icon(Icons.bookmarks), label: 'Thư viện'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }

  Widget _buildDashboardView(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userModel;
    final wrongWords = Provider.of<UserProvider>(context).wrongWords;

    if (user == null) return const Center(child: CircularProgressIndicator());

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String name = data['name'] ?? "Học viên";
        final int streak = data['streak'] ?? 0;
        
        final int dailyLessonsCompleted = data['dailyLessonsCompleted'] ?? 0;
        final int dailyXpEarned = data['dailyXpEarned'] ?? 0;
        
        // Đọc trạng thái đã nhận thưởng hay chưa
        final bool isMission1Claimed = data['rewardMission1Claimed'] ?? false;
        final bool isMission2Claimed = data['rewardMission2Claimed'] ?? false;

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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chào mừng trở lại,', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                                const SizedBox(width: 4),
                                Text('$streak ngày', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // =========================================================
                  // THANH TÌM KIẾM ĐÃ ĐƯỢC PHỤC HỒI CHUYỂN HƯỚNG TỪ ĐIỂN
                  // =========================================================
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DictionaryScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

                  // KHỐI NHIỆM VỤ HÔM NAY
                  const Text('Nhiệm vụ hôm nay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),

                  // NHIỆM VỤ 1 (Thưởng 50 XP)
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

                  // NHIỆM VỤ 2 (Thưởng 100 XP)
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

                  // KHỐI ÔN TẬP CHỈ HIỆN KHI CÓ TỪ SAI
                  if (wrongWords.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Đến hạn ôn tập!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                                const SizedBox(height: 4),
                                Text('Bạn có ${wrongWords.length} từ vựng cần ôn tập lại ngay.', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => setState(() => _currentIndex = 2), // Nhảy sang Tab Ôn tập
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Ôn ngay'),
                          )
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // WIDGET VẼ THẺ NHIỆM VỤ (Bao gồm trạng thái "Đã nhận thưởng")
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
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress, backgroundColor: Colors.grey.shade200, valueColor: AlwaysStoppedAnimation<Color>(iconColor), minHeight: 6,
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          
          // NẾU HOÀN THÀNH HIỆN CHỮ MÀU XANH "ĐÃ NHẬN +XP", NẾU CHƯA THÌ HIỆN SỐ TIẾN TRÌNH
          isClaimed 
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200)
                ),
                child: Text('Đã nhận $rewardText', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
              )
            : Text(progressText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }
}