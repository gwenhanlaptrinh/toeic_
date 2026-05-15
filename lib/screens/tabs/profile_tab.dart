import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
  try {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return;
    final data = await AuthService().getUserData(uid);
    if (mounted) {
      setState(() => userData = data ?? {}); // ← Thêm ?? {}
    }
  } catch (e) {
    print('Lỗi load user: $e');
    if (mounted) setState(() => userData = {});
  }
}

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Avatar
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF1565C0),
                    child: Text(
                      userData!['name']?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(fontSize: 40, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userData!['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    userData!['email'] ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Stats
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('${userData!['totalWordsLearned'] ?? 0}', 'Từ đã học'),
                        _statItem('${userData!['totalScore'] ?? 0}', 'Tổng điểm'),
                        _statItem('${userData!['streak'] ?? 0}🔥', 'Streak'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Logout button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await AuthService().logout();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        }
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text('Đăng xuất',
                          style: TextStyle(color: Colors.red, fontSize: 16)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}