import 'package:dio/dio.dart';

class ApiClient {
  late Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.dictionaryapi.dev/api/v2/entries/en/',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
      ),
    );

    _dio.interceptors.add(
      LogInterceptor(
        responseBody: true,
        requestBody: true,
      ),
    );
  }

  Future<Response> get(String path) async {
    try {
      return await _dio.get(path);
    } on DioException catch (e) {
      throw Exception(_handleError(e));
    }
  }

  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return "Kết nối quá hạn, hãy kiểm tra internet.";

      case DioExceptionType.badResponse:
        return "Không tìm thấy từ này trong từ điển.";

      default:
        return "Đã có lỗi xảy ra, vui lòng thử lại.";
    }
  }
}