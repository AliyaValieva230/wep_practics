import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';
import 'api_exceptions.dart';

Dio buildDio({
  String? Function()? tokenProvider,
  Future<void> Function()? onRefresh,
  void Function()? onLogout,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (s) => s != null && s < 500,
    ),
  );

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      if (kDebugMode) debugPrint('[API] -> ${options.method} ${options.uri}');
      final token = tokenProvider?.call();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onResponse: (response, handler) async {
      final status = response.statusCode ?? 0;
      final opts = response.requestOptions;
      final isAuthEndpoint = opts.path.contains('/auth/');
      final alreadyRetried = opts.extra['auth_retry'] == true;

      if (status == 401 &&
          onRefresh != null &&
          !isAuthEndpoint &&
          !alreadyRetried) {
        try {
          await onRefresh();
          opts.extra['auth_retry'] = true;
          final token = tokenProvider?.call();
          if (token != null) opts.headers['Authorization'] = 'Bearer $token';
          final retried = await dio.fetch(opts);
          return handler.resolve(retried);
        } catch (e) {
          if (kDebugMode) debugPrint('[API] refresh failed: $e');
          onLogout?.call();
        }
      }

      if (status >= 400) {
        return handler.reject(
          DioException(
            requestOptions: opts,
            response: response,
            type: DioExceptionType.badResponse,
            error: mapHttpError(status, response.data),
          ),
          true,
        );
      }
      return handler.next(response);
    },
    onError: (error, handler) async {
      final options = error.requestOptions;
      final isRetryable = error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError;
      if (options.method != 'GET' || !isRetryable) return handler.next(error);
      final retryCount = (options.extra['retry'] as int?) ?? 0;
      if (retryCount >= 3) return handler.next(error);
      final delay = Duration(seconds: 1 << retryCount);
      await Future.delayed(delay);
      options.extra['retry'] = retryCount + 1;
      try {
        final response = await dio.fetch(options);
        return handler.resolve(response);
      } on DioException catch (e) {
        return handler.next(e);
      } catch (_) {
        return handler.next(error);
      }
    },
  ));

  return dio;
}
