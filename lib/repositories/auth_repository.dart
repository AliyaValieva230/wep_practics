import '../models/app_user.dart';

abstract interface class AuthRepository {
  Future<AuthResult> login(String username, String password);
  Future<AuthResult> register({
    required String username,
    required String fullName,
    required String password,
  });
  Future<AppUser> me();
  Future<AuthResult> refresh(String refreshToken);
  Future<void> logout();
}
