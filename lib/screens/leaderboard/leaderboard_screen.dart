import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bảng Xếp Hạng Top Học Viên'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Khối trang trí Header cho Bảng xếp hạng
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: const BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Column(
              children: [
                Icon(Icons.emoji_events, size: 60, color: Colors.amber),
                SizedBox(height: 8),
                Text(
                  'Chăm chỉ mỗi ngày - Cùng nhau tiến bộ',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Danh sách xếp hạng thời gian thực từ Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('totalScore', descending: true) // Sắp xếp điểm từ cao xuống thấp
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('Chưa có dữ liệu xếp hạng.'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    
                    // SỬA LỖI 1: Truyền thêm `doc.id` vào tham số thứ hai theo đúng cấu trúc UserModel.fromMap(data, id)
                    final userItem = UserModel.fromMap(data, doc.id);
                    
                    // Thứ hạng thực tế (index bắt đầu từ 0 nên hạng phải +1)
                    final rank = index + 1; 

                    // Xác định màu sắc biểu tượng cho Top 3
                    Color rankColor = Colors.grey.shade400;
                    Widget rankWidget = Text(
                      '#$rank',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    );

                    if (rank == 1) {
                      rankColor = Colors.amber; // Vàng
                      rankWidget = const Icon(Icons.workspace_premium, color: Colors.amber, size: 30);
                    } else if (rank == 2) {
                      rankColor = Colors.blueGrey.shade300; // Bạc
                      rankWidget = Icon(Icons.workspace_premium, color: Colors.blueGrey.shade300, size: 28);
                    } else if (rank == 3) {
                      rankColor = Colors.brown.shade400; // Đồng
                      rankWidget = Icon(Icons.workspace_premium, color: Colors.brown.shade400, size: 26);
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: rank <= 3 ? 2 : 0.5, // Top 3 sẽ hơi nổi lên một chút
                      child: ListTile(
                        leading: SizedBox(
                          width: 40,
                          // SỬA LỖI 2: Áp dụng rankColor trực tiếp vào Circle hoặc Icon nếu muốn, 
                          // hoặc để bọc nền nhẹ cho Top 3 sử dụng rankColor
                          child: CircleAvatar(
                            backgroundColor: rank <= 3 ? rankColor.withOpacity(0.1) : Colors.transparent,
                            child: rankWidget,
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              userItem.name,
                              style: TextStyle(
                                fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Nếu là tài khoản Plus thì hiện mác nhỏ bên cạnh tên
                            if (userItem.isPlus)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'PRO',
                                  style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text('🔥 Streak: ${userItem.streak} ngày'),
                        trailing: Text(
                          '${userItem.totalScore} Pts',
                          style: TextStyle(
                            color: rank == 1 ? Colors.amber.shade800 : Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}