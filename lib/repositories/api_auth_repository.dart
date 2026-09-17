import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import 'auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  final Dio _dio;
  ApiAuthRepository(this._dio);

  @override
  Future<AuthResult> login(String username, String password) => guard(() async {
        final r = await _dio.post('/auth/login', data: {
          'username': username,
          'password': password,
        });
        return AuthResult.fromJson(r.data as Map<String, dynamic>);
      });

  @override
  Future<AuthResult> register({
    required String username,
    required String fullName,
    required String password,
  }) =>
      guard(() async {
        final r = await _dio.post('/auth/register', data: {
          'username': username,
          'fullName': fullName,
          'password': password,
        });
        return AuthResult.fromJson(r.data as Map<String, dynamic>);
      });

  @override
  Future<AppUser> me() => guard(() async {
        final r = await _dio.get('/auth/me');
        return AppUser.fromJson(r.data as Map<String, dynamic>);
      });

  @override
  Future<AuthResult> refresh(String refreshToken) => guard(() async {
        final r = await _dio.post('/auth/refresh', data: {
          'refreshToken': refreshToken,
        });
        return AuthResult.fromJson(r.data as Map<String, dynamic>);
      });

  @override
  Future<void> logout() => guard(() => _dio.post('/auth/logout'));
}
