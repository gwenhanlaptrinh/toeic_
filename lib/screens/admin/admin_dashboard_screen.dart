// File: lib/screens/admin/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
// Giả sử bạn đã có Firebase Auth để thực hiện đăng xuất
import 'package:firebase_auth/firebase_auth.dart'; 
import 'tabs/bill_approval_tab.dart';
import 'tabs/content_management_tab.dart';
import 'tabs/user_management_tab.dart';
import '../auth/login_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  // Hàm xử lý đăng xuất
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    // Chuyển hướng về màn hình đăng nhập và xóa toàn bộ lịch sử navigation
    if (context.mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bảng Điều Khiển Admin', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blue.shade800,
          foregroundColor: Colors.white,
          // Thêm nút Đăng xuất vào đây
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Đăng xuất',
              onPressed: () => _logout(context),
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.amber,
            tabs: [
              Tab(icon: Icon(Icons.receipt_long), text: 'Duyệt Bill'),
              Tab(icon: Icon(Icons.library_books), text: 'Nội Dung'),
              Tab(icon: Icon(Icons.people), text: 'Học Viên'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            BillApprovalTab(),
            ContentManagementTab(),
            UserManagementTab(),
          ],
        ),
      ),
    );
  }
}