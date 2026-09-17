import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/genre.dart';
import '../models/page_result.dart';
import 'genre_repository.dart';

const List<Genre> seedGenres = [
  Genre(
      id: 1,
      name: 'Роман',
      description: 'Крупное повествовательное произведение'),
  Genre(id: 2, name: 'Эпопея', description: 'Масштабное произведение'),
  Genre(id: 3, name: 'Психологическая проза'),
  Genre(id: 4, name: 'Сатира'),
  Genre(id: 5, name: 'Фэнтези'),
];

class PersistentGenreRepository implements GenreRepository {
  static const String _key = 'genres_v1';
  final SharedPreferences _prefs;
  List<Genre> _genres = [];
  int _nextId = 1;

  PersistentGenreRepository(this._prefs) {
    _restore();
  }

  void _restore() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      _genres = List.from(seedGenres);
      _nextId = _genres.map((g) => g.id).reduce((a, b) => a > b ? a : b) + 1;
      _persist();
      return;
    }
    try {
      final list = jsonDecode(raw) as List;
      _genres =
          list.map((e) => Genre.fromJson(e as Map<String, dynamic>)).toList();
      _nextId = _genres.isEmpty
          ? 1
          : _genres.map((g) => g.id).reduce((a, b) => a > b ? a : b) + 1;
    } catch (e) {
      _genres = List.from(seedGenres);
      _nextId = _genres.map((g) => g.id).reduce((a, b) => a > b ? a : b) + 1;
      _persist();
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
        _key, jsonEncode(_genres.map((g) => g.toJson()).toList()));
  }

  @override
  Future<PageResult<Genre>> find({
    String search = '',
    String sortField = 'name',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var rows = _genres.where((g) => includeDeleted || !g.isDeleted).toList();
    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      rows = rows
          .where((g) =>
              g.name.toLowerCase().contains(q) ||
              (g.description?.toLowerCase().contains(q) ?? false))
          .toList();
    }
    rows.sort((a, b) => sortAscending
        ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
        : b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    final total = rows.length;
    final from = (page - 1) * size;
    final to = (from + size) > total ? total : (from + size);
    final items = from >= total ? <Genre>[] : rows.sublist(from, to);
    return PageResult(items: items, page: page, size: size, total: total);
  }

  @override
  Future<Genre?> findById(int id) async {
    try {
      return _genres.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Genre> create(Genre genre) async {
    final newGenre = genre.copyWith(id: _nextId++);
    _genres.add(newGenre);
    await _persist();
    return newGenre;
  }

  @override
  Future<Genre> update(Genre genre) async {
    final i = _genres.indexWhere((g) => g.id == genre.id);
    if (i == -1) throw StateError('Жанр не найден');
    _genres[i] = genre;
    await _persist();
    return genre;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _genres.indexWhere((g) => g.id == id);
    if (i == -1) throw StateError('Жанр не найден');
    _genres[i] = _genres[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _genres.removeWhere((g) => g.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _genres.indexWhere((g) => g.id == id);
    if (i == -1) throw StateError('Жанр не найден');
    _genres[i] = _genres[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    int count = 0;
    for (final id in ids) {
      final i = _genres.indexWhere((g) => g.id == id && !g.isDeleted);
      if (i != -1) {
        _genres[i] = _genres[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
