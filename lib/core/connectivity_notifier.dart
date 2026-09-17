import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ConnectivityNotifier extends ChangeNotifier {
  final Dio _dio;
  Timer? _timer;
  bool _online = true;

  ConnectivityNotifier(this._dio) {
    _check();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  bool get isOnline => _online;

  Future<void> _check() async {
    try {
      await _dio.get(
        '/__health',
        options: Options(receiveTimeout: const Duration(seconds: 3)),
      );
      _setOnline(true);
    } on DioException catch (e) {
      // Если пришёл ответ (любой код) — сервер доступен, значит онлайн.
      if (e.response != null) {
        _setOnline(true);
      } else {
        _setOnline(false);
      }
    } catch (_) {
      _setOnline(false);
    }
  }

  void _setOnline(bool value) {
    if (_online == value) return;
    _online = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}