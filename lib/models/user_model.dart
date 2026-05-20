class UserModel {
  final String uid;
  final String email;
  final String name;
  final String avatarUrl;
  final int streak;
  final int xp; 
  final bool isPlus;

  UserModel({
    required this.uid,
    required this.email,
    this.name = '',
    this.avatarUrl = '',
    this.streak = 0,
    this.xp = 0, 
    this.isPlus = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      uid: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      streak: map['streak'] ?? 0,
      xp: map['xp'] ?? 0, 
      isPlus: map['isPlus'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'avatarUrl': avatarUrl,
      'streak': streak,
      'xp': xp, 
      'isPlus': isPlus,
    };
  }
}