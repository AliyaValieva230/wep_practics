import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reader.dart';
import '../models/page_result.dart';
import 'reader_repository.dart';

const List<Reader> seedReaders = [
  Reader(id: 1, firstName: 'Иван', lastName: 'Петров', email: 'ivan@mail.ru'),
  Reader(
      id: 2, firstName: 'Мария', lastName: 'Сидорова', email: 'maria@mail.ru'),
];

class PersistentReaderRepository implements ReaderRepository {
  static const String _key = 'readers_v1';
  final SharedPreferences _prefs;
  List<Reader> _readers = [];
  int _nextId = 1;
  int _nextCardId = 10;

  PersistentReaderRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _readers = List.from(seedReaders);
      _nextId = _readers.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _readers =
          list.map((e) => Reader.fromJson(e as Map<String, dynamic>)).toList();
      _nextId = _readers.isEmpty
          ? 1
          : _readers.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
      _nextCardId = _readers.fold(10, (max, r) {
            final id = r.card?.id ?? 0;
            return id > max ? id : max;
          }) +
          1;
    } catch (e) {
      _readers = List.from(seedReaders);
      _nextId = _readers.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
        _key, jsonEncode(_readers.map((r) => r.toJson()).toList()));
  }

  @override
  bool isEmailUnique(String email, {int? excludeId}) {
    return !_readers
        .any((r) => r.email == email && r.id != excludeId && !r.isDeleted);
  }

  @override
  Future<PageResult<Reader>> find({
    String search = '',
    String sortField = 'lastName',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var rows = _readers.where((r) => includeDeleted || !r.isDeleted).toList();
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      rows = rows
          .where((r) =>
              r.lastName.toLowerCase().contains(q) ||
              r.firstName.toLowerCase().contains(q) ||
              r.email.toLowerCase().contains(q))
          .toList();
    }
    rows.sort((a, b) {
      int r;
      switch (sortField) {
        case 'firstName':
          r = a.firstName.compareTo(b.firstName);
          break;
        case 'email':
          r = a.email.compareTo(b.email);
          break;
        default:
          r = a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase());
      }
      return sortAscending ? r : -r;
    });
    final total = rows.length;
    final from = (page - 1) * size;
    final to = (from + size) > total ? total : (from + size);
    final items = from >= total ? <Reader>[] : rows.sublist(from, to);
    return PageResult(items: items, page: page, size: size, total: total);
  }

  @override
  Future<Reader?> findById(int id) async {
    try {
      return _readers.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Reader> create(Reader reader) async {
    final card = reader.card?.copyWith(id: _nextCardId++, readerId: reader.id);
    final newReader = reader.copyWith(id: _nextId++, card: card);
    _readers.add(newReader);
    await _persist();
    return newReader;
  }

  @override
  Future<Reader> update(Reader reader) async {
    final i = _readers.indexWhere((r) => r.id == reader.id);
    if (i == -1) throw StateError('Читатель не найден');
    final updated =
        reader.copyWith(card: reader.card?.copyWith(readerId: reader.id));
    _readers[i] = updated;
    await _persist();
    return updated;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Читатель не найден');
    _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _readers.removeWhere((r) => r.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Читатель не найден');
    _readers[i] = _readers[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    int count = 0;
    for (final id in ids) {
      final i = _readers.indexWhere((r) => r.id == id && !r.isDeleted);
      if (i != -1) {
        _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
