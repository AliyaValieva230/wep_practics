import '../core/api_exceptions.dart';
import '../core/role.dart';
import '../models/app_user.dart';
import 'auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  static final Map<String, ({String password, AppUser user})> _users = {
    'reader': (
      password: 'reader',
      user: const AppUser(
          id: 1,
          username: 'reader',
          fullName: 'Иван Читатель',
          role: Role.reader),
    ),
    'librarian': (
      password: 'librarian',
      user: const AppUser(
          id: 2,
          username: 'librarian',
          fullName: 'Пётр Библиотекарь',
          role: Role.librarian),
    ),
    'admin': (
      password: 'admin',
      user: const AppUser(
          id: 3,
          username: 'admin',
          fullName: 'Анна Администратор',
          role: Role.admin),
    ),
  };

  AppUser? _current;
  int _seq = 0;
  String _mkToken(String kind) =>
      '$kind-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  @override
  Future<AuthResult> login(String username, String password) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final u = _users[username];
    if (u == null || u.password != password) {
      throw const UnauthorizedException('Неверный логин или пароль');
    }
    _current = u.user;
    return AuthResult(
      accessToken: _mkToken('access'),
      refreshToken: _mkToken('refresh'),
      user: u.user,
    );
  }

  @override
  Future<AuthResult> register({
    required String username,
    required String fullName,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_users.containsKey(username)) {
      throw const ConflictException('Такой логин уже существует');
    }
    final user = AppUser(
        id: 100 + _seq++,
        username: username,
        fullName: fullName,
        role: Role.reader);
    _users[username] = (password: password, user: user);
    _current = user;
    return AuthResult(
      accessToken: _mkToken('access'),
      refreshToken: _mkToken('refresh'),
      user: user,
    );
  }

  @override
  Future<AppUser> me() async {
    await Future.delayed(const Duration(milliseconds: 100));
    final u = _current;
    if (u == null) throw const UnauthorizedException();
    return u;
  }

  @override
  Future<AuthResult> refresh(String refreshToken) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final u = _current;
    if (u == null) throw const UnauthorizedException();
    return AuthResult(
      accessToken: _mkToken('access'),
      refreshToken: refreshToken,
      user: u,
    );
  }

  @override
  Future<void> logout() async {
    _current = null;
  }
}
