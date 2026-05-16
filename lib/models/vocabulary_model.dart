class VocabularyModel {
  final String word;
  final String pronunciation;
  final String meaning;
  final String example;
  final String audioUrl;

  VocabularyModel({
    required this.word,
    required this.pronunciation,
    required this.meaning,
    required this.example,
    required this.audioUrl,
  });

  factory VocabularyModel.fromJson(Map<String, dynamic> json) {
    // Xử lý lấy phát âm và audio (đôi khi API trả về mảng rỗng)
    String phonetics = '';
    String audio = '';
    if (json['phonetics'] != null && (json['phonetics'] as List).isNotEmpty) {
      for (var p in json['phonetics']) {
        if (p['text'] != null && phonetics.isEmpty) phonetics = p['text'];
        if (p['audio'] != null && p['audio'].toString().isNotEmpty && audio.isEmpty) audio = p['audio'];
      }
    }

    // Xử lý lấy định nghĩa và ví dụ
    String def = '';
    String ex = '';
    if (json['meanings'] != null && (json['meanings'] as List).isNotEmpty) {
      final definitions = json['meanings'][0]['definitions'] as List;
      if (definitions.isNotEmpty) {
        def = definitions[0]['definition'] ?? '';
        ex = definitions[0]['example'] ?? 'No example available.';
      }
    }

    return VocabularyModel(
      word: json['word'] ?? '',
      pronunciation: phonetics,
      meaning: def,
      example: ex,
      audioUrl: audio,
    );
  }
}