import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

const List<Book> seedBooks = [
  Book(
      id: 1,
      title: 'Война и мир',
      isbn: '978-5-17-118913-0',
      year: 1869,
      pages: 1225,
      publisherId: 1,
      authorIds: [1],
      genreIds: [1, 2],
      copiesTotal: 10,
      copiesAvailable: 8),
  Book(
      id: 2,
      title: 'Преступление и наказание',
      isbn: '978-5-17-118910-9',
      year: 1866,
      pages: 672,
      publisherId: 1,
      authorIds: [2],
      genreIds: [1, 3],
      copiesTotal: 5,
      copiesAvailable: 3),
  Book(
      id: 3,
      title: 'Мастер и Маргарита',
      isbn: '978-5-17-118911-6',
      year: 1967,
      pages: 512,
      publisherId: 2,
      authorIds: [3],
      genreIds: [1, 4],
      copiesTotal: 8,
      copiesAvailable: 6),
  Book(
      id: 4,
      title: 'Анна Каренина',
      isbn: '978-5-17-118912-3',
      year: 1877,
      pages: 864,
      publisherId: 1,
      authorIds: [1],
      genreIds: [1, 2],
      copiesTotal: 7,
      copiesAvailable: 4),
  Book(
      id: 5,
      title: 'Гарри Поттер',
      isbn: '978-5-389-18416-7',
      year: 1997,
      pages: 432,
      publisherId: 3,
      authorIds: [4],
      genreIds: [5, 6],
      copiesTotal: 15,
      copiesAvailable: 12),
];

class PersistentBookRepository implements BookRepository {
  static const String _key = 'books_v1';
  final SharedPreferences _prefs;
  List<Book> _books = [];
  int _nextId = 1;

  PersistentBookRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _books = List.from(seedBooks);
      _nextId = _books.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _books =
          list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
      _nextId = _books.isEmpty
          ? 1
          : _books.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
    } catch (e) {
      _books = List.from(seedBooks);
      _nextId = _books.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
        _key, jsonEncode(_books.map((b) => b.toJson()).toList()));
  }

  bool isIsbnUnique(String isbn, {int? excludeId}) {
    return !_books
        .any((b) => b.isbn == isbn && b.id != excludeId && !b.isDeleted);
  }

  @override
  Future<PageResult<Book>> find({
    String search = '',
    int? genreId,
    int? publisherId,
    int? yearFrom,
    int? yearTo,
    String sortField = 'title',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
    CancelToken? cancelToken,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var rows = _books.where((b) => includeDeleted || !b.isDeleted).toList();
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      rows = rows
          .where((b) =>
              b.title.toLowerCase().contains(q) ||
              b.isbn.toLowerCase().contains(q))
          .toList();
    }
    if (genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(genreId)).toList();
    }
    if (publisherId != null) {
      rows = rows.where((b) => b.publisherId == publisherId).toList();
    }
    if (yearFrom != null) {
      rows = rows.where((b) => b.year >= yearFrom).toList();
    }
    if (yearTo != null) {
      rows = rows.where((b) => b.year <= yearTo).toList();
    }
    rows.sort((a, b) {
      int r;
      switch (sortField) {
        case 'year':
          r = a.year.compareTo(b.year);
          break;
        case 'pages':
          r = a.pages.compareTo(b.pages);
          break;
        default:
          r = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
      return sortAscending ? r : -r;
    });
    final total = rows.length;
    final from = (page - 1) * size;
    final to = (from + size) > total ? total : (from + size);
    final items = from >= total ? <Book>[] : rows.sublist(from, to);
    return PageResult(items: items, page: page, size: size, total: total);
  }

  @override
  Future<Book?> findById(int id) async {
    try {
      return _books.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Book> create(Book book) async {
    final newBook = book.copyWith(id: _nextId++);
    _books.add(newBook);
    await _persist();
    return newBook;
  }

  @override
  Future<Book> update(Book book) async {
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i == -1) throw StateError('Книга не найдена');
    _books[i] = book;
    await _persist();
    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга не найдена');
    _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _books.removeWhere((b) => b.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга не найдена');
    _books[i] = _books[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    int count = 0;
    for (final id in ids) {
      final i = _books.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
