import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/post_model.dart';
import 'comment_sheet.dart';
// Import CommentSheet ở phần sau nếu bạn tách file, tạm thời mình sẽ hướng dẫn luồng chính trước.

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // HÀM ĐĂNG BÀI
  Future<void> _submitPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    _postController.clear(); // Xóa khung nhập ngay cho mượt
    FocusScope.of(context).unfocus(); // Đóng bàn phím

    await _firestore.collection('posts').add({
      'uid': user.uid,
      'authorName': user.name.isNotEmpty ? user.name : 'Học viên TOEIC',
      'authorAvatar': user.avatarUrl,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
      'commentCount': 0,
    });
  }

  // HÀM THẢ/RÚT TIM
  Future<void> _toggleLike(PostModel post) async {
    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid == null) return;

    final postRef = _firestore.collection('posts').doc(post.id);

    if (post.likes.contains(uid)) {
      // Đã tim -> Rút tim
      await postRef.update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      // Chưa tim -> Thả tim
      await postRef.update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  // HÀM XÓA BÀI (Chỉ chủ bài viết mới được xóa)
  Future<void> _deletePost(String postId) async {
    await _firestore.collection('posts').doc(postId).delete();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthProvider>().userModel;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cộng đồng TOEIC'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // KHU VỰC ĐĂNG BÀI
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage:
                      currentUser?.avatarUrl != null &&
                          currentUser!.avatarUrl.isNotEmpty
                      ? NetworkImage(currentUser.avatarUrl)
                      : null,
                  child:
                      currentUser?.avatarUrl == null ||
                          currentUser!.avatarUrl.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _postController,
                    decoration: InputDecoration(
                      hintText: 'Bạn có câu hỏi hay mẹo học nào không?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: _submitPost,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // DANH SÁCH BÀI ĐĂNG (FEED)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError)
                  return const Center(child: Text('Đã xảy ra lỗi'));
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text('Chưa có bài đăng nào. Hãy là người đầu tiên!'),
                  );
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final post = PostModel.fromFirestore(docs[index]);
                    final isLiked =
                        currentUser != null &&
                        post.likes.contains(currentUser.uid);
                    final isMyPost =
                        currentUser != null && post.uid == currentUser.uid;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // HEADER: Avatar + Tên + Nút Xóa
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: post.authorAvatar.isNotEmpty
                                      ? NetworkImage(post.authorAvatar)
                                      : null,
                                  child: post.authorAvatar.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "${post.timestamp.hour}:${post.timestamp.minute.toString().padLeft(2, '0')} - ${post.timestamp.day}/${post.timestamp.month}/${post.timestamp.year}",
                                        style: TextStyle(
                                          color: Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isMyPost)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deletePost(post.id),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // NỘI DUNG
                            Text(
                              post.content,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 12),

                            // NÚT TƯƠNG TÁC (TIM & BÌNH LUẬN)
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleLike(post),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isLiked
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isLiked
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('${post.likes.length}'),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                                GestureDetector(
                                  onTap: () {
                                    // Kích hoạt đẩy Bottom Sheet bình luận lên màn hình theo ID bài đăng
                                    CommentSheet.show(context, post.id);
                                  },
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.chat_bubble_outline,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text('${post.commentCount}'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
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
