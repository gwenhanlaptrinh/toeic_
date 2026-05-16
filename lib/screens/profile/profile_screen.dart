import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lắng nghe dữ liệu User hiện tại
    final user = context.watch<AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ của tôi'),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Avatar và Tên
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.blue.shade100,
                        child: const Icon(Icons.person, size: 50, color: Colors.blue),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        user.email,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Thống kê
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events, color: Colors.orange),
                    title: const Text('Tổng điểm'),
                    trailing: Text('${user.totalScore}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.local_fire_department, color: Colors.red),
                    title: const Text('Chuỗi ngày học (Streak)'),
                    trailing: Text('${user.streak} ngày', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 30),

                // Nút Đăng xuất
                ElevatedButton.icon(
                  onPressed: () async {
                    // Gọi hàm đăng xuất từ Provider
                    await context.read<AuthProvider>().signOut();
                    if (context.mounted) {
                      // Đẩy người dùng về màn hình Login và xóa lịch sử trang
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                )
              ],
            ),
    );
  }
}