import 'package:flutter_test/flutter_test.dart';
import 'package:wep_practics/core/validators.dart';

void main() {
  group('V.required', () {
    test('пустая строка отклоняется', () {
      expect(V.required()(''), isNotNull);
      expect(V.required()('   '), isNotNull);
      expect(V.required()(null), isNotNull);
    });

    test('непустая строка принимается', () {
      expect(V.required()('Война и мир'), isNull);
    });
  });

  group('V.length', () {
    test('короче минимума — ошибка', () {
      expect(V.length(min: 3)('ab'), isNotNull);
    });

    test('длиннее максимума — ошибка', () {
      expect(V.length(max: 5)('abcdef'), isNotNull);
    });

    test('в диапазоне — ок', () {
      expect(V.length(min: 2, max: 5)('abc'), isNull);
    });
  });

  group('V.integer', () {
    test('не число', () {
      expect(V.integer()('abc'), isNotNull);
    });

    test('ниже минимума', () {
      expect(V.integer(min: 10)('5'), isNotNull);
    });

    test('в диапазоне', () {
      expect(V.integer(min: 10, max: 20)('15'), isNull);
    });

    test('пустая строка — ошибка', () {
      expect(V.integer()(''), isNotNull);
    });
  });

  group('V.positiveInt', () {
    test('ноль отклоняется', () {
      expect(V.positiveInt()('0'), isNotNull);
    });

    test('единица принимается', () {
      expect(V.positiveInt()('1'), isNull);
    });

    test('отрицательное отклоняется', () {
      expect(V.positiveInt()('-5'), isNotNull);
    });
  });

  group('V.isbn', () {
    test('10 цифр — ок', () {
      expect(V.isbn()('1234567890'), isNull);
    });

    test('13 цифр с дефисами — ок', () {
      expect(V.isbn()('978-5-17-118913-0'), isNull);
    });

    test('13 цифр без дефисов — ок', () {
      expect(V.isbn()('9785171189130'), isNull);
    });

    test('короткий — ошибка', () {
      expect(V.isbn()('12345'), isNotNull);
    });

    test('буквы — ошибка', () {
      expect(V.isbn()('abcdefghij'), isNotNull);
    });

    test('пустая строка — ошибка', () {
      expect(V.isbn()(''), isNotNull);
    });
  });

  group('V.email', () {
    test('валидный email', () {
      expect(V.email()('a@b.c'), isNull);
    });

    test('email с плюсом', () {
      expect(V.email()('user+tag@mail.ru'), isNull);
    });

    test('без собаки — ошибка', () {
      expect(V.email()('abc'), isNotNull);
    });

    test('без домена — ошибка', () {
      expect(V.email()('abc@'), isNotNull);
    });

    test('пустая строка — ошибка', () {
      expect(V.email()(''), isNotNull);
    });
  });

  group('V.strongPassword', () {
    test('короткий пароль отклоняется', () {
      expect(V.strongPassword()('Ab1!'), isNotNull);
    });

    test('без цифры отклоняется', () {
      expect(V.strongPassword()('Abcdefg!'), isNotNull);
    });

    test('без спецсимвола отклоняется', () {
      expect(V.strongPassword()('Abcdefg1'), isNotNull);
    });

    test('сильный пароль принимается', () {
      expect(V.strongPassword()('Secret123!'), isNull);
    });

    test('пустой пароль отклоняется', () {
      expect(V.strongPassword()(''), isNotNull);
    });
  });

  group('V.combine', () {
    test('возвращает первую ошибку', () {
      final v = V.combine([V.required(), V.length(min: 5)]);
      expect(v(''), isNotNull);
      expect(v('ab'), isNotNull);
      expect(v('abcdef'), isNull);
    });

    test('все проходят — null', () {
      final v = V.combine([V.required(), V.length(max: 10)]);
      expect(v('ok'), isNull);
    });
  });
}
