import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _flutterTts.setLanguage("en-US");
    _flutterTts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ Tay Từ Vựng'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: uid == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem thư viện.'))
          : StreamBuilder<QuerySnapshot>(
              // Lắng nghe danh sách từ đã lưu, xếp từ mới lưu lên trên đầu
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .collection('saved_words')
                  .orderBy('savedAt', descending: true)
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 70, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Thư viện của bạn đang trống.\nHãy nhấn tim các từ vựng khi tra cứu!',
                          textAlign: TextAlign.center, // Đã sửa lỗi CenterTextAlignment
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                        ), // Đã xóa bỏ đoạn copyWithStyle lỗi
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final word = data['word'] ?? '';
                    final pronunciation = data['pronunciation'] ?? '';
                    final meaning = data['meaning'] ?? '';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Row(
                          children: [
                            Text(
                              word,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                            ),
                            const SizedBox(width: 8),
                            if (pronunciation.isNotEmpty)
                              Expanded(
                                child: Text(
                                  pronunciation,
                                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6), // Đã dọn dẹp thuộc tính onParagraphChanged lỗi
                          child: Text(
                            meaning,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, color: Colors.black87),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Nút nghe phát âm ngay tại thư viện
                            IconButton(
                              icon: const Icon(Icons.volume_up, color: Colors.blue),
                              onPressed: () => _flutterTts.speak(word),
                            ),
                            // Nút xóa nhanh từ vựng ra khỏi thư viện
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () {
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(uid)
                                    .collection('saved_words')
                                    .doc(word)
                                    .delete();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}