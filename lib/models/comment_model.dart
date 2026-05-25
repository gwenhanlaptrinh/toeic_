import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String uid;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime timestamp;
  final List<String> likes;     // Mảng chứa UID những người thích cmt này
  final String? parentId;       // ID của bình luận gốc (nếu là cmt con)
  final String? replyToName;     // Tên người được tag (@B, @C...)

  CommentModel({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.timestamp,
    required this.likes,
    this.parentId,
    this.replyToName,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CommentModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      authorName: data['authorName'] ?? 'Học viên',
      authorAvatar: data['authorAvatar'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
      parentId: data['parentId'],
      replyToName: data['replyToName'],
    );
  }
}