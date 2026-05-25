import 'package:flutter/material.dart';
import '../models/vocabulary_model.dart';
import '../services/dictionary_service.dart';

class DictionaryProvider extends ChangeNotifier {
  final DictionaryService _dictionaryService = DictionaryService();
  
  VocabularyModel? _searchedWord;
  bool _isLoading = false;
  String? _errorMessage;

  VocabularyModel? get searchedWord => _searchedWord;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> search(String word) async {
  if (word.trim().isEmpty) return;

  _isLoading = true;
  _errorMessage = null;
  _searchedWord = null;
  notifyListeners();

  try {
    _searchedWord = await _dictionaryService
        .searchWord(word.trim().toLowerCase())
        .timeout(const Duration(seconds: 20));
  } catch (e) {
    _errorMessage = e.toString().replaceFirst('Exception: ', '');
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  // Hàm xóa kết quả khi người dùng đóng ô tìm kiếm
  void clearSearch() {
    _searchedWord = null;
    _errorMessage = null;
    notifyListeners();
  }
}