import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/author.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

const List<Author> seedAuthors = [
  Author(id: 1, firstName: 'Лев', lastName: 'Толстой', country: 'Россия'),
  Author(id: 2, firstName: 'Фёдор', lastName: 'Достоевский', country: 'Россия'),
  Author(id: 3, firstName: 'Михаил', lastName: 'Булгаков', country: 'Россия'),
  Author(
      id: 4,
      firstName: 'Джоан',
      lastName: 'Роулинг',
      country: 'Великобритания'),
  Author(
      id: 5, firstName: 'Эрих Мария', lastName: 'Ремарк', country: 'Германия'),
  Author(
      id: 6,
      firstName: 'Джордж',
      lastName: 'Оруэлл',
      country: 'Великобритания'),
  Author(id: 7, firstName: 'Джеймс', lastName: 'Джойс', country: 'Ирландия'),
  Author(id: 8, firstName: 'Габриэль', lastName: 'Маркес', country: 'Колумбия'),
];

class PersistentAuthorRepository implements AuthorRepository {
  static const String _key = 'authors_v1';
  final SharedPreferences _prefs;
  List<Author> _authors = [];
  int _nextId = 1;

  PersistentAuthorRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _authors = List.from(seedAuthors);
      _nextId = _authors.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _authors =
          list.map((e) => Author.fromJson(e as Map<String, dynamic>)).toList();
      _nextId = _authors.isEmpty
          ? 1
          : _authors.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
    } catch (e) {
      _authors = List.from(seedAuthors);
      _nextId = _authors.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
        _key, jsonEncode(_authors.map((a) => a.toJson()).toList()));
  }

  @override
  Future<PageResult<Author>> find({
    String search = '',
    String? country,
    String sortField = 'lastName',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var rows = _authors.where((a) => includeDeleted || !a.isDeleted).toList();
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      rows = rows
          .where((a) =>
              a.lastName.toLowerCase().contains(q) ||
              a.firstName.toLowerCase().contains(q) ||
              a.country.toLowerCase().contains(q))
          .toList();
    }
    if (country != null && country.isNotEmpty) {
      rows = rows.where((a) => a.country == country).toList();
    }
    rows.sort((a, b) {
      int r;
      switch (sortField) {
        case 'firstName':
          r = a.firstName.compareTo(b.firstName);
          break;
        case 'country':
          r = a.country.compareTo(b.country);
          break;
        default:
          r = a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
      }
      return sortAscending ? r : -r;
    });
    final total = rows.length;
    final from = (page - 1) * size;
    final to = (from + size) > total ? total : (from + size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);
    return PageResult(items: items, page: page, size: size, total: total);
  }

  @override
  Future<Author?> findById(int id) async {
    try {
      return _authors.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Author> create(Author author) async {
    final newAuthor = author.copyWith(id: _nextId++);
    _authors.add(newAuthor);
    await _persist();
    return newAuthor;
  }

  @override
  Future<Author> update(Author author) async {
    final i = _authors.indexWhere((a) => a.id == author.id);
    if (i == -1) throw StateError('Автор не найден');
    _authors[i] = author;
    await _persist();
    return author;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор не найден');
    _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _authors.removeWhere((a) => a.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор не найден');
    _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    int count = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
