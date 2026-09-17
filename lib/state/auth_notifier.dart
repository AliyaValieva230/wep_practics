import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../core/role.dart';
import '../models/app_user.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

class AuthNotifier extends ChangeNotifier {
  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kLastActivity = 'auth_last_activity';
  static const _kSessionStart = 'auth_session_start';

  static const Duration idleTimeout = Duration(minutes: 3);
  static const Duration idleWarning = Duration(seconds: 30);
  static const Duration sessionLifetime = Duration(hours: 2);

  final SharedPreferences _prefs;
  final AuthRepository _api;
  AuthNotifier(this._prefs, this._api);

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  String? _sessionEndReason;

  Timer? _idleTimer;
  Timer? _warningTimer;
  Timer? _sessionTimer;
  Timer? _warningTick;

  int _warningSecondsLeft = 0;
  bool _refreshing = false;
  Future<void>? _refreshInFlight;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get sessionEndReason => _sessionEndReason;
  int get warningSecondsLeft => _warningSecondsLeft;
  bool get warningActive => _warningSecondsLeft > 0;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;

  bool has(Role role) => _user != null && _user!.role.level >= role.level;

  Future<void> bootstrap() async {
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    if (access == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    _accessToken = access;
    _refreshToken = refresh;
    try {
      _user = await _api.me();
      _status = AuthStatus.authenticated;
      _resumeSessionTimers();
    } on UnauthorizedException {
      if (refresh != null) {
        try {
          await _refreshWith(refresh);
          _status = AuthStatus.authenticated;
          _resumeSessionTimers();
        } catch (_) {
          await _clear();
        }
      } else {
        await _clear();
      }
    } catch (_) {
      _user = null;
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    _sessionEndReason = null;
    final r = await _api.login(username, password);
    await _persist(r);
    _status = AuthStatus.authenticated;
    _startSessionTimers();
    notifyListeners();
  }

  Future<void> register({
    required String username,
    required String fullName,
    required String password,
  }) async {
    _sessionEndReason = null;
    final r = await _api.register(
      username: username,
      fullName: fullName,
      password: password,
    );
    await _persist(r);
    _status = AuthStatus.authenticated;
    _startSessionTimers();
    notifyListeners();
  }

  Future<void> logout({String? reason}) async {
    try {
      await _api.logout();
    } catch (_) {}
    _sessionEndReason = reason;
    await _clear();
    notifyListeners();
  }

  Future<void> refreshTokens() {
    if (_refreshing && _refreshInFlight != null) return _refreshInFlight!;
    _refreshing = true;
    _refreshInFlight = () async {
      try {
        final r = _refreshToken;
        if (r == null) throw const UnauthorizedException();
        await _refreshWith(r);
        notifyListeners();
      } finally {
        _refreshing = false;
        _refreshInFlight = null;
      }
    }();
    return _refreshInFlight!;
  }

  Future<void> _refreshWith(String refresh) async {
    final r = await _api.refresh(refresh);
    await _persist(r);
  }

  Future<void> _persist(AuthResult r) async {
    _accessToken = r.accessToken;
    _refreshToken = r.refreshToken;
    _user = r.user;
    await _prefs.setString(_kAccess, r.accessToken);
    await _prefs.setString(_kRefresh, r.refreshToken);
  }

  Future<void> _clear() async {
    _idleTimer?.cancel();
    _warningTimer?.cancel();
    _warningTick?.cancel();
    _sessionTimer?.cancel();
    _warningSecondsLeft = 0;
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _status = AuthStatus.unauthenticated;
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kLastActivity);
    await _prefs.remove(_kSessionStart);
  }

  void _startSessionTimers() {
    _sessionTimer?.cancel();
    _prefs.setString(_kSessionStart, DateTime.now().toIso8601String());
    _sessionTimer = Timer(sessionLifetime, () {
      logout(reason: 'Превышена максимальная длительность сессии');
    });
    _resetIdle();
  }

  void _resumeSessionTimers() {
    final startRaw = _prefs.getString(_kSessionStart);
    final start = startRaw != null ? DateTime.tryParse(startRaw) : null;
    if (start == null) {
      _startSessionTimers();
      return;
    }
    final left = sessionLifetime - DateTime.now().difference(start);
    if (left.isNegative) {
      logout(reason: 'Превышена максимальная длительность сессии');
      return;
    }
    _sessionTimer = Timer(left, () {
      logout(reason: 'Превышена максимальная длительность сессии');
    });

    final lastRaw = _prefs.getString(_kLastActivity);
    final last = lastRaw != null ? DateTime.tryParse(lastRaw) : null;
    final sinceLast = last != null ? DateTime.now().difference(last) : null;
    if (sinceLast != null && sinceLast >= idleTimeout) {
      logout(reason: 'Сессия завершена по неактивности');
      return;
    }
    _armIdle(sinceLast == null ? idleTimeout : idleTimeout - sinceLast);
  }

  void noteActivity() {
    if (!isAuthenticated) return;
    _prefs.setString(_kLastActivity, DateTime.now().toIso8601String());
    _resetIdle();
  }

  void _resetIdle() {
    _idleTimer?.cancel();
    _warningTimer?.cancel();
    _warningTick?.cancel();
    _warningSecondsLeft = 0;
    _armIdle(idleTimeout);
  }

  void _armIdle(Duration remaining) {
    _idleTimer = Timer(remaining, () {
      logout(reason: 'Сессия завершена по неактивности');
    });
    final warnAfter = remaining - idleWarning;
    if (warnAfter.isNegative || warnAfter == Duration.zero) {
      _beginWarning();
    } else {
      _warningTimer = Timer(warnAfter, _beginWarning);
    }
  }

  void _beginWarning() {
    _warningSecondsLeft = idleWarning.inSeconds;
    notifyListeners();
    _warningTick?.cancel();
    _warningTick = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!isAuthenticated) {
        t.cancel();
        return;
      }
      _warningSecondsLeft -= 1;
      if (_warningSecondsLeft <= 0) {
        t.cancel();
        notifyListeners();
        return;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _warningTimer?.cancel();
    _warningTick?.cancel();
    _sessionTimer?.cancel();
    super.dispose();
  }
}
