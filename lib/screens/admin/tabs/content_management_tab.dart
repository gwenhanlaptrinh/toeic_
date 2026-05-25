// File: lib/screens/admin/tabs/content_management_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../dialogs/manage_content_dialog.dart';

class ContentManagementTab extends StatefulWidget {
  const ContentManagementTab({super.key});

  @override
  State<ContentManagementTab> createState() => _ContentManagementTabState();
}

class _ContentManagementTabState extends State<ContentManagementTab> {
  bool _showTopics = true; 

  // ========================================================
  // 👑 TÍNH NĂNG MỚI: XÓA DÂY CHUYỀN BÀI HỌC VÀ TỪ VỰNG/QUIZ
  // ========================================================
  Future<void> _deleteLessonWithCascade(BuildContext context, String lessonId, String lessonTitle) async {
    // Hiện màn hình loading chờ xử lý xóa dữ liệu ngầm
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Tìm tất cả flashcards thuộc bài học này
      final flashcardsSnap = await FirebaseFirestore.instance
          .collection('flashcards')
          .where('lessonId', isEqualTo: lessonId)
          .get();

      // 2. Đưa các lệnh xóa flashcard vào hàng đợi batch
      for (var doc in flashcardsSnap.docs) {
        batch.delete(doc.reference);
      }

      // 3. Đưa lệnh xóa chính bài học đó vào batch
      batch.delete(FirebaseFirestore.instance.collection('lessons').doc(lessonId));

      // 4. Thực thi đồng loạt (Nếu một cái lỗi, tất cả sẽ hủy - An toàn dữ liệu)
      await batch.commit();

      if (context.mounted) {
        Navigator.pop(context); // Tắt hộp thoại loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa sạch bài học "$lessonTitle" và các từ vựng đi kèm!'), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Tắt hộp thoại loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xảy ra khi xóa: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  // ========================================================
  // 👑 TÍNH NĂNG MỚI: XÓA DÂY CHUYỀN CHỦ ĐỀ -> BÀI HỌC -> TỪ VỰNG
  // ========================================================
  Future<void> _deleteTopicWithCascade(BuildContext context, String topicId, String topicTitle) async {
    // Hiện màn hình loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();

      // 1. Tìm tất cả bài học (lessons) thuộc chủ đề này
      final lessonsSnap = await FirebaseFirestore.instance
          .collection('lessons')
          .where('topicId', isEqualTo: topicId)
          .get();

      for (var lessonDoc in lessonsSnap.docs) {
        // 2. Với mỗi bài học, quét tìm tất cả từ vựng/quiz con của nó
        final flashcardsSnap = await FirebaseFirestore.instance
            .collection('flashcards')
            .where('lessonId', isEqualTo: lessonDoc.id)
            .get();

        for (var flashcardDoc in flashcardsSnap.docs) {
          batch.delete(flashcardDoc.reference); // Xóa sạch từ vựng/quiz rác
        }

        batch.delete(lessonDoc.reference); // Xóa bài học con
      }

      // 3. Cuối cùng, xóa chính Chủ đề cha (Topic)
      batch.delete(FirebaseFirestore.instance.collection('topics').doc(topicId));

      // 4. Kích hoạt xóa dây chuyền hàng loạt trên Firebase
      await batch.commit();

      if (context.mounted) {
        Navigator.pop(context); // Tắt màn hình loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa thành công Chủ đề "$topicTitle" cùng toàn bộ Bài học & Từ vựng con!'), backgroundColor: Colors.red)
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Tắt màn hình loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gặp lỗi khi xóa hệ thống: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  // Hộp thoại cảnh báo xác nhận trước khi xóa
  void _confirmDeleteDialog({required String title, required String message, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showTopicFormDialog({String? docId, String? currentTitle, String? currentDescription}) {
    final titleController = TextEditingController(text: currentTitle);
    final descController = TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(docId == null ? 'Thêm Chủ Đề Mới' : 'Cập Nhật Chủ Đề', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tên chủ đề (Topic Title)')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Mô tả ngắn gọn')),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isEmpty) return;
                final Map<String, dynamic> data = {
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'icon': 'school_rounded', 
                };
                if (docId == null) {
                  data['timestamp'] = FieldValue.serverTimestamp();
                  await FirebaseFirestore.instance.collection('topics').add(data);
                } else {
                  await FirebaseFirestore.instance.collection('topics').doc(docId).update(data);
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Lưu lại'),
            ),
          ],
        );
      },
    );
  }

  void _showLessonFormDialog({String? docId, String? currentTitle, int? currentOrder, String? currentTopicId}) {
    final titleController = TextEditingController(text: currentTitle);
    final orderController = TextEditingController(text: currentOrder != null ? currentOrder.toString() : '1');
    String? selectedTopicId = currentTopicId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(docId == null ? 'Thêm Bài Học Mới' : 'Cập Nhật Bài Học', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Tên bài học (Lesson Title)')),
                    TextField(controller: orderController, decoration: const InputDecoration(labelText: 'Thứ tự bài học (Số)'), keyboardType: TextInputType.number),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('topics').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const CircularProgressIndicator();
                        final topics = snapshot.data!.docs;
                        if (topics.isEmpty) {
                          return const Text('Cần phải tạo Chủ đề (Topic) trước khi tạo Bài học!', style: TextStyle(color: Colors.red, fontSize: 13));
                        }
                        final containsCurrent = topics.any((doc) => doc.id == selectedTopicId);
                        if (!containsCurrent) {
                          selectedTopicId = topics.isNotEmpty ? topics.first.id : null;
                        }
                        return DropdownButtonFormField<String>(
                          value: selectedTopicId,
                          decoration: const InputDecoration(labelText: 'Thuộc Chủ đề nào?'),
                          items: topics.map((doc) {
                            final topicData = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text(topicData['title'] ?? 'Không tên'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedTopicId = value;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty || selectedTopicId == null) return;
                    final Map<String, dynamic> data = {
                      'title': titleController.text.trim(),
                      'topicId': selectedTopicId,
                      'order': int.tryParse(orderController.text.trim()) ?? 1,
                    };
                    if (docId == null) {
                      await FirebaseFirestore.instance.collection('lessons').add(data);
                    } else {
                      await FirebaseFirestore.instance.collection('lessons').doc(docId).update(data);
                    }
                    if (mounted) Navigator.pop(context);
                  },
                  child: const Text('Lưu lại'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.grey.shade100,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Chủ Đề (Topics)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _showTopics ? Colors.blue.shade800 : Colors.grey.shade300,
                      foregroundColor: _showTopics ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => setState(() => _showTopics = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.menu_book_rounded),
                    label: const Text('Bài Học (Lessons)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_showTopics ? Colors.blue.shade800 : Colors.grey.shade300,
                      foregroundColor: !_showTopics ? Colors.white : Colors.black87,
                    ),
                    onPressed: () => setState(() => _showTopics = false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _showTopics ? _buildTopicsRealtimeList() : _buildLessonsRealtimeList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue.shade800,
        onPressed: () => _showTopics ? _showTopicFormDialog() : _showLessonFormDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildTopicsRealtimeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('topics').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Chưa có chủ đề nào. Nhấn nút + để tạo mới.'));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Không tên';
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.folder, color: Colors.white)),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['description'] ?? 'Không có mô tả'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showTopicFormDialog(docId: doc.id, currentTitle: title, currentDescription: data['description'])),
                    // 👑 ĐÃ SỬA: Thay thế hàm xóa đơn thường thành xóa dây chuyền liên đới
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red), 
                      onPressed: () => _confirmDeleteDialog(
                        title: 'Xóa Toàn Bộ Chủ Đề?',
                        message: 'Hành động này cực kỳ nguy hiểm! Xác nhận xóa chủ đề "$title"? Hệ thống sẽ tự động quét và XÓA SẠCH toàn bộ Bài học & Từ vựng/Quiz con thuộc chủ đề này.',
                        onConfirm: () => _deleteTopicWithCascade(context, doc.id, title),
                      ),
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

  Widget _buildLessonsRealtimeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('lessons').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Chưa có bài học nào. Nhấn nút + để tạo mới.'));

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? 'Không tên';
            final String topicId = data['topicId'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.menu_book, color: Colors.white)),
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('topics').doc(topicId).snapshots(),
                        builder: (context, topicSnap) {
                          if (!topicSnap.hasData || !topicSnap.data!.exists) {
                            return Text('Thứ tự: ${data['order'] ?? 1} | Nhóm: Đã bị xóa hoặc ẩn');
                          }
                          final topicData = topicSnap.data!.data() as Map<String, dynamic>;
                          return Text(
                            'Thứ tự bài: ${data['order'] ?? 1} | Thuộc nhóm: ${topicData['title']}',
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w500),
                          );
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showLessonFormDialog(docId: doc.id, currentTitle: title, currentOrder: data['order'], currentTopicId: data['topicId'])),
                          // 👑 ĐÃ SỬA: Thêm hộp thoại xác nhận và xóa sạch Flashcards con đi kèm
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red), 
                            onPressed: () => _confirmDeleteDialog(
                              title: 'Xóa Bài Học?',
                              message: 'Bạn có chắc chắn muốn xóa bài học "$title"? Tất cả kho Từ vựng & câu hỏi Quiz thuộc bài này sẽ bị xóa bỏ hoàn toàn.',
                              onConfirm: () => _deleteLessonWithCascade(context, doc.id, title),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber.shade100,
                              foregroundColor: Colors.amber.shade900,
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.style, size: 18),
                            label: const Text('Nội dung học (Flashcard / Quiz)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => ManageLessonContentDialog(lessonId: doc.id, lessonTitle: title),
                              );
                            },
                          ),
                        ],
                      ),
                    )
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