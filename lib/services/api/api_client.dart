import 'package:dio/dio.dart';

class ApiClient {
  late Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.dictionaryapi.dev/api/v2/entries/en/',
        connectTimeout: const Duration(seconds: 10), // 10s timeout
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Thêm Interceptor để Log dữ liệu ra Console khi debug
    _dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));
  }

  // Hàm GET chung cho toàn app
  Future<Response> get(String path) async {
    try {
      final response = await _dio.get(path);
      return response;
    } on DioException catch (e) {
      // Xử lý lỗi tập trung tại đây
      throw _handleError(e);
    }
  }

  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return "Kết nối quá hạn, hãy kiểm tra internet.";
      case DioExceptionType.badResponse:
        return "Không tìm thấy từ này trong từ điển.";
      default:
        return "Đã có lỗi xảy ra, vui lòng thử lại.";
    }
  }
}