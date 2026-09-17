typedef Validator = String? Function(String?);

class V {
  static Validator required([String msg = 'Поле обязательно']) {
    return (v) => (v == null || v.trim().isEmpty) ? msg : null;
  }

  static Validator length({int min = 0, int max = 255}) {
    return (v) {
      final t = v?.trim() ?? '';
      if (t.length < min) {
        return 'Не короче $min символов';
      }
      if (t.length > max) {
        return 'Не длиннее $max символов';
      }
      return null;
    };
  }

  static Validator integer({int? min, int? max}) {
    return (v) {
      final n = int.tryParse(v?.trim() ?? '');
      if (n == null) {
        return 'Введите целое число';
      }
      if (min != null && n < min) {
        return 'Не меньше $min';
      }
      if (max != null && n > max) {
        return 'Не больше $max';
      }
      return null;
    };
  }

  static Validator positiveInt() => integer(min: 1);

  static Validator email() {
    final re = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    return (v) => re.hasMatch(v?.trim() ?? '') ? null : 'Некорректный email';
  }

  static Validator isbn() {
    return (v) {
      if (v == null || v.trim().isEmpty) {
        return 'Введите ISBN';
      }
      final clean = v.replaceAll(RegExp(r'[-\s]'), '');
      if (clean.length != 13 && clean.length != 10) {
        return 'ISBN: 10 или 13 цифр';
      }
      if (!RegExp(r'^\d+$').hasMatch(clean)) {
        return 'ISBN: только цифры и дефисы';
      }
      return null;
    };
  }

  static Validator strongPassword() {
    final special = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=~`\[\];/\\]');
    return (v) {
      final s = v ?? '';
      final missing = <String>[];
      if (s.length < 8) {
        missing.add('8+ символов');
      }
      if (!RegExp(r'\d').hasMatch(s)) {
        missing.add('цифра');
      }
      if (!special.hasMatch(s)) {
        missing.add('спецсимвол');
      }
      return missing.isEmpty ? null : 'Пароль: нужно ${missing.join(", ")}';
    };
  }

  static Validator combine(List<Validator> list) {
    return (v) {
      for (final f in list) {
        final e = f(v);
        if (e != null) {
          return e;
        }
      }
      return null;
    };
  }
}