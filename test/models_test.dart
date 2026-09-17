import 'package:flutter_test/flutter_test.dart';
import 'package:wep_practics/models/book.dart';
import 'package:wep_practics/models/author.dart';
import 'package:wep_practics/models/genre.dart';
import 'package:wep_practics/models/publisher.dart';
import 'package:wep_practics/models/reader.dart';
import 'package:wep_practics/models/page_result.dart';

void main() {
  group('Book.fromJson', () {
    test('отсутствующие поля не приводят к исключению', () {
      final b = Book.fromJson({'id': 1});
      expect(b.id, 1);
      expect(b.title, '');
      expect(b.isbn, '');
      expect(b.year, 0);
      expect(b.pages, 0);
      expect(b.publisherId, 0);
      expect(b.authorIds, isEmpty);
      expect(b.genreIds, isEmpty);
      expect(b.copiesTotal, 0);
      expect(b.copiesAvailable, 0);
      expect(b.deletedAt, isNull);
      expect(b.isDeleted, isFalse);
    });

    test('полный JSON парсится корректно', () {
      final b = Book.fromJson({
        'id': 5,
        'title': 'Война и мир',
        'isbn': '978-5-17-118913-0',
        'year': 1869,
        'pages': 1225,
        'publisherId': 2,
        'authorIds': [1, 2],
        'genreIds': [3],
        'copiesTotal': 10,
        'copiesAvailable': 7,
      });
      expect(b.id, 5);
      expect(b.title, 'Война и мир');
      expect(b.year, 1869);
      expect(b.authorIds, [1, 2]);
      expect(b.genreIds, [3]);
      expect(b.copiesAvailable, 7);
      expect(b.isDeleted, isFalse);
    });

    test('deletedAt распознаётся и isDeleted == true', () {
      final b = Book.fromJson({
        'id': 1,
        'deletedAt': '2024-01-01T00:00:00.000',
      });
      expect(b.deletedAt, isNotNull);
      expect(b.isDeleted, isTrue);
    });

    test('toJson / fromJson — round-trip', () {
      const original = Book(
        id: 7,
        title: 'T',
        isbn: '1234567890',
        year: 2000,
        pages: 100,
        publisherId: 1,
        authorIds: [1, 2],
        genreIds: [3],
        copiesTotal: 5,
        copiesAvailable: 3,
      );
      final restored = Book.fromJson(original.toJson());
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.authorIds, original.authorIds);
      expect(restored.genreIds, original.genreIds);
    });

    test('copyWith clearDeletedAt обнуляет deletedAt', () {
      final b = Book(
        id: 1,
        title: 'X',
        isbn: '1',
        year: 2000,
        pages: 1,
        publisherId: 1,
        authorIds: const [],
        genreIds: const [],
        copiesTotal: 1,
        copiesAvailable: 1,
        deletedAt: DateTime(2024),
      );
      expect(b.copyWith(clearDeletedAt: true).deletedAt, isNull);
    });
  });

  group('Author', () {
    test('fromJson минимальный', () {
      final a = Author.fromJson({'id': 1});
      expect(a.id, 1);
      expect(a.firstName, '');
      expect(a.lastName, '');
      expect(a.middleName, isNull);
      expect(a.country, '');
    });

    test('fullName склеивает части без пустых', () {
      const a =
          Author(id: 1, firstName: 'Лев', lastName: 'Толстой', country: 'RU');
      expect(a.fullName, 'Толстой Лев');
    });

    test('fullName с отчеством', () {
      const a = Author(
        id: 1,
        firstName: 'Лев',
        lastName: 'Толстой',
        middleName: 'Николаевич',
        country: 'RU',
      );
      expect(a.fullName, 'Толстой Лев Николаевич');
    });

    test('copyWith с clearDeletedAt обнуляет deletedAt', () {
      final a = Author(
        id: 1,
        firstName: 'X',
        lastName: 'Y',
        country: 'Z',
        deletedAt: DateTime(2024),
      );
      expect(a.copyWith(clearDeletedAt: true).deletedAt, isNull);
    });
  });

  group('Genre.fromJson', () {
    test('минимальный JSON', () {
      final g = Genre.fromJson({'id': 3});
      expect(g.id, 3);
      expect(g.name, '');
      expect(g.description, isNull);
      expect(g.isDeleted, isFalse);
    });

    test('полный JSON', () {
      final g =
          Genre.fromJson({'id': 5, 'name': 'Фэнтези', 'description': 'd'});
      expect(g.name, 'Фэнтези');
      expect(g.description, 'd');
    });
  });

  group('Publisher.fromJson', () {
    test('минимальный JSON', () {
      final p = Publisher.fromJson({'id': 1});
      expect(p.id, 1);
      expect(p.name, '');
      expect(p.address, isNull);
    });

    test('полный JSON', () {
      final p =
          Publisher.fromJson({'id': 2, 'name': 'АСТ', 'address': 'Москва'});
      expect(p.name, 'АСТ');
      expect(p.address, 'Москва');
    });
  });

  group('Reader.fromJson', () {
    test('без карты card == null', () {
      final r = Reader.fromJson({'id': 1, 'email': 'a@b.c'});
      expect(r.card, isNull);
      expect(r.isDeleted, isFalse);
    });

    test('fullName собирается из частей', () {
      const r =
          Reader(id: 1, firstName: 'Иван', lastName: 'Петров', email: 'a@b.c');
      expect(r.fullName, 'Петров Иван');
    });

    test('полный JSON с картой', () {
      final r = Reader.fromJson({
        'id': 1,
        'firstName': 'Иван',
        'lastName': 'Петров',
        'email': 'a@b.c',
        'card': {
          'id': 10,
          'readerId': 1,
          'barcode': 'ABC12345',
          'issuedAt': '2024-01-01T00:00:00.000',
          'expiresAt': '2025-01-01T00:00:00.000',
          'isActive': true,
        },
      });
      expect(r.card, isNotNull);
      expect(r.card!.barcode, 'ABC12345');
      expect(r.card!.isActive, isTrue);
    });
  });

  group('PageResult', () {
    test('totalPages округляет вверх', () {
      const p = PageResult<int>(items: [1, 2, 3], page: 1, size: 10, total: 25);
      expect(p.totalPages, 3);
    });

    test('total == 0 — одна страница', () {
      const p = PageResult<int>(items: [], page: 1, size: 10, total: 0);
      expect(p.totalPages, 1);
    });

    test('hasPrevious / hasNext на первой странице', () {
      const p = PageResult<int>(items: [1], page: 1, size: 10, total: 25);
      expect(p.hasPrevious, isFalse);
      expect(p.hasNext, isTrue);
    });

    test('hasPrevious / hasNext на последней странице', () {
      const p = PageResult<int>(items: [1], page: 3, size: 10, total: 25);
      expect(p.hasPrevious, isTrue);
      expect(p.hasNext, isFalse);
    });
  });
}
