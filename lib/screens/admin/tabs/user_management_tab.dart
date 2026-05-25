import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementTab extends StatelessWidget {
  const UserManagementTab({super.key});

  // Hộp thoại xác nhận Xóa Học Viên vĩnh viễn
  void _showDeleteUserConfirmation(BuildContext context, String uid, String userName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa Học Viên', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text('Xác nhận xóa học viên "$userName" khỏi cơ sở dữ liệu? Toàn bộ quá trình học tập sẽ biến mất.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(uid).delete();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã loại bỏ học viên.'), backgroundColor: Colors.red));
                }
              },
              child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Hộp thoại xác nhận Gỡ Quyền Premium Plus
  void _showRevokePlusConfirmation(BuildContext context, String uid, String userName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Gỡ Quyền Plus', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          content: Text('Bạn có chắc chắn muốn gỡ quyền PREMIUM PLUS của học viên "$userName" không? Tài khoản sẽ quay về trạng thái phổ thông.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'isPlus': false,
                  'plusExpiredAt': FieldValue.delete(), // Xóa luôn trường ngày hết hạn nếu có
                });
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã hạ quyền tài khoản xuống Phổ thông.'), backgroundColor: Colors.orange)
                  );
                }
              },
              child: const Text('Xác nhận gỡ', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Hệ thống chưa ghi nhận học viên nào đăng ký.'));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final userDoc = docs[index];
            final data = userDoc.data() as Map<String, dynamic>;
            final isPlus = data['isPlus'] ?? false;
            final name = data['name'] ?? 'Học viên ẩn danh';

            String expireText = '';
            if (isPlus && data['plusExpiredAt'] != null) {
              final DateTime date = (data['plusExpiredAt'] as Timestamp).toDate();
              expireText = ' (Hết hạn: ${date.day}/${date.month}/${date.year})';
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isPlus ? Colors.amber : Colors.transparent, width: 1.5),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isPlus ? Colors.amber.shade100 : Colors.grey.shade200,
                  child: Icon(Icons.person, color: isPlus ? Colors.amber.shade800 : Colors.grey.shade600),
                ),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['email'] ?? 'Không có email'),
                    const SizedBox(height: 4),
                    Text(
                      isPlus ? 'Hội viên PREMIUM PLUS$expireText' : 'Tài khoản Phổ thông (Free)',
                      style: TextStyle(
                        color: isPlus ? Colors.amber.shade900 : Colors.grey.shade600,
                        fontWeight: isPlus ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min, // Giới hạn kích thước của Row vừa đủ các nút
                  children: [
                    // Nếu là tài khoản Plus thì hiện nút Gỡ Quyền Plus màu cam
                    if (isPlus)
                      IconButton(
                        icon: const Icon(Icons.card_membership_rounded, color: Colors.orange),
                        tooltip: 'Gỡ quyền PLUS',
                        onPressed: () => _showRevokePlusConfirmation(context, userDoc.id, name),
                      ),
                    // Luôn giữ nút Xóa vĩnh viễn user màu đỏ
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      tooltip: 'Xóa tài khoản',
                      onPressed: () => _showDeleteUserConfirmation(context, userDoc.id, name),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}