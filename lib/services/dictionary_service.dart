import 'package:dio/dio.dart';
import '../models/vocabulary_model.dart';
import 'api/api_client.dart';

class DictionaryService {
  final ApiClient _apiClient = ApiClient();

  Future<VocabularyModel> searchWord(String word) async {
    try {
      // Gọi API. Base URL đã được setup là: https://api.dictionaryapi.dev/api/v2/entries/en/
      final response = await _apiClient.get(word);
      
      // API này luôn trả về một mảng (List) các kết quả, ta lấy phần tử đầu tiên
      if (response.statusCode == 200 && response.data != null && response.data.isNotEmpty) {
        return VocabularyModel.fromJson(response.data[0]);
      } else {
        throw Exception("Không tìm thấy từ này.");
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw Exception("Không tìm thấy từ vựng trong từ điển.");
      }
      throw Exception("Lỗi kết nối mạng. Vui lòng thử lại.");
    } catch (e) {
      throw Exception("Đã xảy ra lỗi: $e");
    }
  }
}