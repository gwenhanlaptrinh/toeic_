import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../courses/courses_screen.dart';
import '../review/review_screen.dart';
import '../library/library_screen.dart';
import '../profile/profile_screen.dart';
import '../leaderboard/leaderboard_screen.dart'; 
import '../dictionary/dictionary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Danh sách 5 màn hình tương ứng với 5 nút dưới Bottom Navigation
    final List<Widget> screens = [
      _buildDashboardView(context),
      const CoursesScreen(),
      const ReviewScreen(),
      const LibraryScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      // IndexedStack đóng băng các màn hình, chuyển qua lại không bị load lại dữ liệu từ đầu
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Courses'),
          NavigationDestination(icon: Icon(Icons.replay_circle_filled_outlined), selectedIcon: Icon(Icons.replay_circle_filled), label: 'Review'),
          NavigationDestination(icon: Icon(Icons.bookmarks_outlined), selectedIcon: Icon(Icons.bookmarks), label: 'Library'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // =========================================================================
  // GIAO DIỆN HÌNH DASHBOARD CHÍNH (Được tích hợp trực tiếp, không dùng file tab rời)
  // =========================================================================
  Widget _buildDashboardView(BuildContext context) {
    // Lắng nghe trạng thái và dữ liệu User từ AuthProvider liên tục theo thời gian thực
    final user = context.watch<AuthProvider>().userModel;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. K H Ố I  H E A D E R (Thông tin cá nhân, Nút Bảng Xếp Hạng & Badge Premium)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Khối bên trái: Avatar và Tên
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: user?.avatarUrl.isNotEmpty == true 
                            ? NetworkImage(user!.avatarUrl) 
                            : null,
                        child: user?.avatarUrl.isEmpty == true || user?.avatarUrl == null
                            ? const Icon(Icons.person, color: Colors.blue) 
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello ${user?.name ?? 'bạn'},',
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                              overflow: TextOverflow.ellipsis, // Cắt chữ nếu tên quá dài
                            ),
                            const Text(
                              'Sẵn sàng học chưa?',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Khối bên phải: Cúp Bảng xếp hạng và Mác PLUS
                Row(
                  children: [
                    // NÚT BẢNG XẾP HẠNG
                    IconButton(
                      icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 30),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 4),

                    // MÁC PLUS
                    if (user?.isPlus == true)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text('PLUS', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // =========================================================
            // THANH TÌM KIẾM CHUYỂN HƯỚNG SANG TỪ ĐIỂN (Vừa mới thêm)
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

            // 2. K H Ố I  D A I L Y  P R O G R E S S (Tiến độ học trong ngày & Streak)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mục tiêu hôm nay', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      SizedBox(height: 8),
                      Text('15 / 20 từ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    children: [
                      const Text('Streak học tập', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.local_fire_department, color: Colors.orangeAccent),
                          const SizedBox(width: 4),
                          Text('${user?.streak ?? 0}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 3. K H Ố I  S M A R T  R E V I E W (Core Feature - Hệ thống ôn tập thông minh)
            const Text(
              '📌 Need Review Today',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.red),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Đến hạn ôn tập!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Bạn có từ vựng cần ôn lại ngay hôm nay.', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Chuyển sang màn hình Review (vị trí index số 2 trên thanh Bottom Nav)
                      setState(() {
                        _currentIndex = 2;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Ôn ngay'),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}