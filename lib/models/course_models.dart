// File: lib/models/course_models.dart

class TopicModel {
  final String id;
  final String title;
  final String description;
  final String icon;
  double progress; 

  TopicModel({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    this.progress = 0.0,
  });

  // Chuẩn hóa: Đưa Map lên trước, id ra sau, progress là named parameter
  factory TopicModel.fromMap(Map<String, dynamic> map, String id, {double progress = 0.0}) {
    return TopicModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      icon: map['icon'] ?? 'school',
      progress: progress,
    );
  }
}

class LessonModel {
  final String id;
  final String topicId;
  final String title;
  final int order;
  bool isCompleted;

  LessonModel({
    required this.id,
    required this.topicId,
    required this.title,
    required this.order,
    this.isCompleted = false,
  });

  // Chuẩn hóa: Đưa Map lên trước, id ra sau, các biến cấu hình đưa vào trong ngoặc nhọn {}
  factory LessonModel.fromMap(Map<String, dynamic> map, String id, {String? topicId, bool isCompleted = false}) {
    return LessonModel(
      id: id,
      topicId: topicId ?? (map['topicId'] ?? ''),
      title: map['title'] ?? '',
      order: map['order'] ?? 0,
      isCompleted: isCompleted,
    );
  }
}

class FlashcardModel {
  final String id;
  final String word;
  final String meaning;
  final String pronunciation;
  final String example; 
  final List<String> options;
  final int correctAnswerIndex;

  FlashcardModel({
    required this.id,
    required this.word,
    required this.meaning,
    required this.pronunciation,
    required this.example,
    required this.options,
    required this.correctAnswerIndex,
  });

  factory FlashcardModel.fromMap(Map<String, dynamic> map, String id) {
    return FlashcardModel(
      id: id,
      word: map['word'] ?? '',
      meaning: map['meaning'] ?? '',
      pronunciation: map['pronunciation'] ?? '',
      example: map['example'] ?? 'No example provided.',
      options: List<String>.from(map['options'] ?? []),
      correctAnswerIndex: map['correctAnswerIndex'] ?? 0,
    );
  }
}