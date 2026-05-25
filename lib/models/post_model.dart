import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String uid;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime timestamp;
  final List<String> likes;
  final int commentCount;

  PostModel({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.timestamp,
    required this.likes,
    this.commentCount = 0,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      uid: data['uid'] ?? '',
      authorName: data['authorName'] ?? 'Người dùng',
      authorAvatar: data['authorAvatar'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'likes': likes,
      'commentCount': commentCount,
    };
  }
}