import 'package:flutter_test/flutter_test.dart';
import 'package:wep_practics/core/role.dart';

void main() {
  group('Role.fromWire', () {
    test('ADMIN → admin', () {
      expect(Role.fromWire('ADMIN'), Role.admin);
    });

    test('ADMINISTRATOR → admin', () {
      expect(Role.fromWire('ADMINISTRATOR'), Role.admin);
    });

    test('admin в нижнем регистре → admin', () {
      expect(Role.fromWire('admin'), Role.admin);
    });

    test('LIBRARIAN → librarian', () {
      expect(Role.fromWire('LIBRARIAN'), Role.librarian);
    });

    test('librarian в нижнем регистре → librarian', () {
      expect(Role.fromWire('librarian'), Role.librarian);
    });

    test('READER → reader', () {
      expect(Role.fromWire('READER'), Role.reader);
    });

    test('неизвестное значение → reader', () {
      expect(Role.fromWire('xyz'), Role.reader);
    });

    test('пустая строка → reader', () {
      expect(Role.fromWire(''), Role.reader);
    });

    test('null → reader', () {
      expect(Role.fromWire(null), Role.reader);
    });
  });

  group('Role.level', () {
    test('reader — базовый уровень 1', () {
      expect(Role.reader.level, 1);
    });

    test('librarian выше reader', () {
      expect(Role.librarian.level > Role.reader.level, isTrue);
    });

    test('admin выше librarian', () {
      expect(Role.admin.level > Role.librarian.level, isTrue);
    });

    test('admin имеет максимальный уровень', () {
      expect(Role.admin.level, 3);
    });
  });

  group('Role.label', () {
    test('подписи ролей на русском', () {
      expect(Role.reader.label, 'Читатель');
      expect(Role.librarian.label, 'Библиотекарь');
      expect(Role.admin.label, 'Администратор');
    });
  });

  group('Role.homeRoute', () {
    test('у каждой роли есть свой маршрут', () {
      expect(Role.reader.homeRoute, '/my-loans');
      expect(Role.librarian.homeRoute, '/librarian');
      expect(Role.admin.homeRoute, '/admin');
    });

    test('маршруты уникальны', () {
      final routes = Role.values.map((r) => r.homeRoute).toSet();
      expect(routes.length, Role.values.length);
    });
  });

  group('Иерархия прав', () {
    test('admin >= librarian', () {
      expect(Role.admin.level >= Role.librarian.level, isTrue);
    });

    test('admin >= reader', () {
      expect(Role.admin.level >= Role.reader.level, isTrue);
    });

    test('librarian >= reader', () {
      expect(Role.librarian.level >= Role.reader.level, isTrue);
    });

    test('reader НЕ >= librarian', () {
      expect(Role.reader.level >= Role.librarian.level, isFalse);
    });

    test('librarian НЕ >= admin', () {
      expect(Role.librarian.level >= Role.admin.level, isFalse);
    });
  });
}
