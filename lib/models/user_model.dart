class UserModel {
  final String uid;
  final String email;
  final String name;
  final String avatarUrl;
  final int streak;
  final int totalScore;
  final bool isPlus;

  UserModel({
    required this.uid,
    required this.email,
    this.name = '',
    this.avatarUrl = '',
    this.streak = 0,
    this.totalScore = 0,
    this.isPlus = false,
  });

  // Chuyển từ JSON (Firestore) sang Object trong Flutter
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      streak: map['streak'] ?? 0,
      totalScore: map['totalScore'] ?? 0,
      isPlus: map['isPlus'] ?? false,
    );
  }

  // Chuyển từ Object sang JSON để lưu lên Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'streak': streak,
      'totalScore': totalScore,
      'isPlus': isPlus,
    };
  }
}