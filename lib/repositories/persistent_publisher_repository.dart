import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/publisher.dart';
import '../models/page_result.dart';
import 'publisher_repository.dart';

const List<Publisher> seedPublishers = [
  Publisher(id: 1, name: 'АСТ', address: 'Москва'),
  Publisher(id: 2, name: 'Эксмо', address: 'Москва'),
  Publisher(id: 3, name: 'Росмэн', address: 'Москва'),
];

class PersistentPublisherRepository implements PublisherRepository {
  static const String _key = 'publishers_v1';
  final SharedPreferences _prefs;
  List<Publisher> _publishers = [];
  int _nextId = 1;

  PersistentPublisherRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _publishers = List.from(seedPublishers);
      _nextId =
          _publishers.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _publishers = list
          .map((e) => Publisher.fromJson(e as Map<String, dynamic>))
          .toList();
      _nextId = _publishers.isEmpty
          ? 1
          : _publishers.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    } catch (e) {
      _publishers = List.from(seedPublishers);
      _nextId =
          _publishers.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
        _key, jsonEncode(_publishers.map((p) => p.toJson()).toList()));
  }

  @override
  Future<PageResult<Publisher>> find({
    String search = '',
    String sortField = 'name',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var rows =
        _publishers.where((p) => includeDeleted || !p.isDeleted).toList();
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      rows = rows
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              (p.address?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    rows.sort((a, b) => sortAscending
        ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
        : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    final total = rows.length;
    final from = (page - 1) * size;
    final to = (from + size) > total ? total : (from + size);
    final items = from >= total ? <Publisher>[] : rows.sublist(from, to);
    return PageResult(items: items, page: page, size: size, total: total);
  }

  @override
  Future<Publisher?> findById(int id) async {
    try {
      return _publishers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Publisher> create(Publisher publisher) async {
    final newPublisher = publisher.copyWith(id: _nextId++);
    _publishers.add(newPublisher);
    await _persist();
    return newPublisher;
  }

  @override
  Future<Publisher> update(Publisher publisher) async {
    final i = _publishers.indexWhere((p) => p.id == publisher.id);
    if (i == -1) throw StateError('Издательство не найдено');
    _publishers[i] = publisher;
    await _persist();
    return publisher;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _publishers.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Издательство не найдено');
    _publishers[i] = _publishers[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _publishers.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _publishers.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Издательство не найдено');
    _publishers[i] = _publishers[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    int count = 0;
    for (final id in ids) {
      final i = _publishers.indexWhere((p) => p.id == id && !p.isDeleted);
      if (i != -1) {
        _publishers[i] = _publishers[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
