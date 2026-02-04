import 'package:dio/dio.dart';

import 'logger_service.dart';

class DioLoggingInterceptor extends Interceptor {
  final LoggerService _logger = LoggerService();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.apiRequest(
      endpoint: options.path,
      method: options.method,
      requestBody: options.data is FormData ? {'FormData': true} : options.data,
      headers: options.headers.cast<String, dynamic>(),
    );

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final duration = DateTime.now().difference(
      DateTime.parse(response.requestOptions.extra['requestTime'] ??
          DateTime.now().toString()),
    );

    _logger.apiResponse(
      endpoint: response.requestOptions.path,
      method: response.requestOptions.method,
      statusCode: response.statusCode ?? 0,
      responseBody: response.data,
      duration: duration,
    );

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.apiError(
      endpoint: err.requestOptions.path,
      method: err.requestOptions.method,
      statusCode: err.response?.statusCode,
      errorMessage: err.message ?? 'Unknown error',
      duration: const Duration(milliseconds: 0),
    );

    super.onError(err, handler);
  }
}
