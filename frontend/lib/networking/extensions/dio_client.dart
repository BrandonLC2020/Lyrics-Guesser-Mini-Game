import 'package:dio/dio.dart';
import 'dart:io';

import 'package:flutter/foundation.dart';

class DioClient {
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  static Dio get dio {
    return Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    )..interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
  }
}
