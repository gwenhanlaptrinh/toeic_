import 'package:cloud_firestore/cloud_firestore.dart';

class WordOfDayService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Danh sách từ mẫu (sau này lấy từ Firestore)
  final List<Map<String, dynamic>> _words = [
    {
      'word': 'Perseverance',
      'phonetic': '/ˌpɜːrsɪˈvɪərəns/',
      'type': 'noun',
      'meaning': 'Sự kiên trì, bền bỉ',
      'example': 'Her perseverance helped her pass the TOEIC exam.',
      'exampleVi': 'Sự kiên trì của cô ấy đã giúp cô vượt qua kỳ thi TOEIC.',
    },
    {
      'word': 'Negotiate',
      'phonetic': '/nɪˈɡəʊʃieɪt/',
      'type': 'verb',
      'meaning': 'Đàm phán, thương lượng',
      'example': 'We need to negotiate the contract terms.',
      'exampleVi': 'Chúng ta cần đàm phán các điều khoản hợp đồng.',
    },
    {
      'word': 'Efficient',
      'phonetic': '/ɪˈfɪʃnt/',
      'type': 'adjective',
      'meaning': 'Hiệu quả, năng suất',
      'example': 'She is an efficient manager.',
      'exampleVi': 'Cô ấy là một người quản lý hiệu quả.',
    },
    {
      'word': 'Revenue',
      'phonetic': '/ˈrevənjuː/',
      'type': 'noun',
      'meaning': 'Doanh thu, thu nhập',
      'example': 'The company increased its revenue by 20%.',
      'exampleVi': 'Công ty đã tăng doanh thu lên 20%.',
    },
    {
      'word': 'Deadline',
      'phonetic': '/ˈdedlaɪn/',
      'type': 'noun',
      'meaning': 'Hạn chót, thời hạn',
      'example': 'Please submit your report before the deadline.',
      'exampleVi': 'Vui lòng nộp báo cáo trước hạn chót.',
    },
  ];

  Map<String, dynamic> getWordOfDay() {
    final dayIndex = DateTime.now().day % _words.length;
    return _words[dayIndex];
  }

  // Lưu từ vào thư viện user
  Future<void> saveWord(String uid, Map<String, dynamic> word) async {
    await _firestore
        .collection('savedWords')
        .doc(uid)
        .collection('words')
        .doc(word['word'])
        .set({
      ...word,
      'savedAt': Timestamp.now(),
    });
  }

  // Kiểm tra đã lưu chưa
  Future<bool> isWordSaved(String uid, String word) async {
    final doc = await _firestore
        .collection('savedWords')
        .doc(uid)
        .collection('words')
        .doc(word)
        .get();
    return doc.exists;
  }

  Future<void> deleteWord(String uid, String word) async {
    await _firestore
        .collection('savedWords')
        .doc(uid)
        .collection('words')
        .doc(word)
        .delete();
  }
}