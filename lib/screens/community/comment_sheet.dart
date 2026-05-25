import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/comment_model.dart';

class CommentSheet extends StatefulWidget {
  final String postId;
  const CommentSheet({super.key, required this.postId});

  static void show(BuildContext context, String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentSheet(postId: postId),
    );
  }

  @override
  State<CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<CommentSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _targetParentId; 
  String? _replyingToName; 

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours}g trước';
    return '${time.day}/${time.month}';
  }

  // HÀM GỬI BÌNH LUẬN / PHẢN HỒI
  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AuthProvider>().userModel;
    if (user == null) return;

    _commentController.clear();
    final parentIdToSend = _targetParentId;
    final replyToNameToSend = _replyingToName;

    setState(() {
      _targetParentId = null;
      _replyingToName = null;
    });
    _focusNode.unfocus();

    await _firestore.collection('posts').doc(widget.postId).collection('comments').add({
      'uid': user.uid,
      'authorName': user.name.isNotEmpty ? user.name : 'Học viên',
      'authorAvatar': user.avatarUrl,
      'content': text,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': [],
      'parentId': parentIdToSend,      
      'replyToName': replyToNameToSend,  
    });

    await _firestore.collection('posts').doc(widget.postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  // HÀM THẢ TIM BÌNH LUẬN
  Future<void> _toggleLikeComment(String commentId, List<String> likes) async {
    final uid = context.read<AuthProvider>().userModel?.uid;
    if (uid == null) return;

    final cmtRef = _firestore.collection('posts').doc(widget.postId).collection('comments').doc(commentId);
    if (likes.contains(uid)) {
      await cmtRef.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await cmtRef.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  // HÀM XÓA BÌNH LUẬN TRONG FIRESTORE
  Future<void> _deleteComment(CommentModel comment) async {
    final commentsRef = _firestore.collection('posts').doc(widget.postId).collection('comments');

    if (comment.parentId == null) {
      // Xóa bình luận GỐC (Xóa luôn các bình luận con của nó)
      final childComments = await commentsRef.where('parentId', isEqualTo: comment.id).get();
      int deleteCount = 1 + childComments.docs.length; 

      WriteBatch batch = _firestore.batch();
      batch.delete(commentsRef.doc(comment.id));
      for (var doc in childComments.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await _firestore.collection('posts').doc(widget.postId).update({
        'commentCount': FieldValue.increment(-deleteCount),
      });
    } else {
      // Chỉ xóa 1 bình luận CON
      await commentsRef.doc(comment.id).delete();
      await _firestore.collection('posts').doc(widget.postId).update({
        'commentCount': FieldValue.increment(-1),
      });
    }
  }

  // HỘP THOẠI XÁC NHẬN XÓA
  void _showDeleteDialog(CommentModel comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa bình luận', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text(comment.parentId == null 
            ? 'Bạn có chắc chắn muốn xóa bình luận này? Tất cả các phản hồi liên quan cũng sẽ bị xóa.'
            : 'Bạn có chắc chắn muốn xóa phản hồi này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteComment(comment);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.watch<AuthProvider>().userModel?.uid;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          children: [
            // Thanh kéo nhỏ
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Bình luận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.5),

            // DANH SÁCH BÌNH LUẬN
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('posts').doc(widget.postId).collection('comments').orderBy('timestamp', descending: false).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  
                  final docs = snapshot.data?.docs ?? [];
                  List<CommentModel> allComments = docs.map((d) => CommentModel.fromFirestore(d)).toList();

                  List<CommentModel> mainComments = allComments.where((c) => c.parentId == null).toList();
                  Map<String, List<CommentModel>> replyGroups = {};
                  for (var c in allComments) {
                    if (c.parentId != null) {
                      replyGroups.putIfAbsent(c.parentId!, () => []).add(c);
                    }
                  }

                  List<CommentModel> displayList = [];
                  for (var main in mainComments) {
                    displayList.add(main);
                    if (replyGroups.containsKey(main.id)) {
                      displayList.addAll(replyGroups[main.id]!);
                    }
                  }

                  if (displayList.isEmpty) {
                    return Center(child: Text('Chưa có bình luận nào.', style: TextStyle(color: Colors.grey.shade400)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: displayList.length,
                    itemBuilder: (context, index) {
                      final comment = displayList[index];
                      final isReply = comment.parentId != null; 
                      final isLiked = currentUid != null && comment.likes.contains(currentUid);
                      final isMyComment = currentUid == comment.uid; 

                      return GestureDetector(
                        onLongPress: isMyComment ? () => _showDeleteDialog(comment) : null,
                        child: Container(
                          color: Colors.transparent, 
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: EdgeInsets.only(left: isReply ? 44.0 : 0.0), // Thụt lề nếu là cmt con
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: isReply ? 13 : 16,
                                  backgroundImage: comment.authorAvatar.isNotEmpty ? NetworkImage(comment.authorAvatar) : null,
                                  child: comment.authorAvatar.isEmpty ? Icon(Icons.person, size: isReply ? 14 : 18) : null,
                                ),
                                const SizedBox(width: 10),

                                // NỘI DUNG CHỮ & NÚT
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.authorName,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 3),
                                      
                                      RichText(
                                        text: TextSpan(
                                          style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.25),
                                          children: [
                                            if (comment.replyToName != null)
                                              TextSpan(
                                                text: '@${comment.replyToName} ',
                                                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                                              ),
                                            TextSpan(text: comment.content),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 5),

                                      // HÀNG DƯỚI: Thời gian, Trả lời, Xóa (nếu có)
                                      Row(
                                        children: [
                                          Text(_formatTime(comment.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                                          const SizedBox(width: 16),
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _targetParentId = comment.parentId ?? comment.id;
                                                _replyingToName = comment.authorName;
                                              });
                                              _focusNode.requestFocus();
                                            },
                                            child: Text('Trả lời', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                                          ),
                                          // NÚT XÓA CHỈ HIỆN KHI LÀ CMT CỦA CHÍNH MÌNH
                                          if (isMyComment) ...[
                                            const SizedBox(width: 16),
                                            GestureDetector(
                                              onTap: () => _showDeleteDialog(comment),
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline, size: 14, color: Colors.red.shade300),
                                                  const SizedBox(width: 2),
                                                  Text('Xóa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade300)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // NÚT THẢ TIM
                                GestureDetector(
                                  onTap: () => _toggleLikeComment(comment.id, comment.likes),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: isLiked ? Colors.red : Colors.grey.shade400,
                                        size: 14,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${comment.likes.length}',
                                        style: TextStyle(color: Colors.grey.shade400, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            
            const Divider(height: 1, thickness: 0.5),

            // KHUNG NHẬP TEXT BÌNH LUẬN
            SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_replyingToName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      color: Colors.grey.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Đang trả lời ${_replyingToName}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic)),
                          GestureDetector(
                            onTap: () => setState(() { _targetParentId = null; _replyingToName = null; }),
                            child: Icon(Icons.close, size: 16, color: Colors.grey.shade500),
                          )
                        ],
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: Colors.white,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            focusNode: _focusNode,
                            maxLines: null,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: _replyingToName != null ? 'Trả lời bình luận...' : 'Thêm bình luận...',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.blue, size: 22),
                          onPressed: _sendComment,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}