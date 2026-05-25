import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillApprovalTab extends StatelessWidget {
  const BillApprovalTab({super.key});

  Future<void> _approveRequest(BuildContext context, String requestId, String uid) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final DateTime oneYearLater = DateTime.now().add(const Duration(days: 365));

      await FirebaseFirestore.instance.collection('payment_requests').doc(requestId).update({'status': 'approved'});
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'isPlus': true,
        'plusExpiredAt': Timestamp.fromDate(oneYearLater),
      }); 
      
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Đã duyệt cấp PLUS thời hạn 1 năm thành công!'), backgroundColor: Colors.green)
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Lỗi duyệt bill: $e'), backgroundColor: Colors.red)
      );
    }
  }

  Future<void> _rejectRequest(BuildContext context, String requestId) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await FirebaseFirestore.instance.collection('payment_requests').doc(requestId).update({'status': 'rejected'});
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Đã từ chối yêu cầu chuyển khoản này.'), backgroundColor: Colors.orange)
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red)
      );
    }
  }

  void _showRequestDetails(BuildContext context, Map<String, dynamic> data, String requestId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          titlePadding: const EdgeInsets.only(left: 24, top: 16, right: 8, bottom: 0),
          // 👑 ĐÃ SỬA: Đưa nút Đóng (X) lên trên cùng bên phải
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Chi Tiết Yêu Cầu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text('Học viên: ${data['name'] ?? 'Không tên'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Email: ${data['email'] ?? 'Không có'}'),
                const SizedBox(height: 16),
                const Text('Ảnh chuyển khoản đối chiếu:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                data['imageBase64'] != null
                    ? Container(
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            base64Decode(data['imageBase64']),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) => Container(height: 150, color: Colors.grey.shade900, child: const Center(child: Text('Lỗi định dạng ảnh', style: TextStyle(color: Colors.red)))),
                          ),
                        ),
                      )
                    : Container(height: 150, color: Colors.grey.shade200, child: const Center(child: Text('Không có đính kèm ảnh'))),
              ],
            ),
          ),
          // 👑 ĐÃ SỬA: Căn giữa 2 nút bấm và phóng to kích thước
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.only(bottom: 24, top: 12),
          actions: [
            ElevatedButton.icon(
              onPressed: () => _rejectRequest(context, requestId), 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600, 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ), 
              icon: const Icon(Icons.cancel),
              label: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _approveRequest(context, requestId, data['uid'] ?? ''), 
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700, 
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ), 
              icon: const Icon(Icons.check_circle),
              label: const Text('Duyệt PLUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('payment_requests').where('status', isEqualTo: 'pending').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('Không có hóa đơn nào đang chờ phê duyệt.', style: TextStyle(fontSize: 15, color: Colors.grey)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.payment, color: Colors.white)),
                title: Text(data['name'] ?? 'Học viên ẩn danh', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${data['email']}\nĐang đợi kích hoạt gói Premium'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showRequestDetails(context, data, doc.id),
              ),
            );
          },
        );
      },
    );
  }
}