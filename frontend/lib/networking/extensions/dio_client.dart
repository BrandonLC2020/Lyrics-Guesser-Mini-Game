import 'package:dio/dio.dart';

class DioClient {
  static const String _baseUrl = 'http://localhost:8000';

  static Dio get dio {
    return Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 3),
      ),
    )..interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
  }
}
