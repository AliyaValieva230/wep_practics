import 'package:flutter/foundation.dart';
import '../models/publisher.dart';
import '../models/page_result.dart';
import '../repositories/publisher_repository.dart';
import '../repositories/book_repository.dart';
import '../core/debounce.dart';

enum LoadStatus { idle, loading, success, error }

class PublisherListNotifier extends ChangeNotifier {
  final PublisherRepository _repo;
  final BookRepository _bookRepo;
  PublisherListNotifier(this._repo, this._bookRepo);

  String _search = '';
  String _sortField = 'name';
  bool _sortAscending = true;
  int _page = 1;
  int _size = 10;
  bool _includeDeleted = false;

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  PageResult<Publisher> _result = PageResult.empty();
  final Set<int> _selected = {};
  final Debouncer _debouncer = Debouncer();

  LoadStatus get status => _status;
  String? get error => _error;
  PageResult<Publisher> get result => _result;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  String get search => _search;
  String get sortField => _sortField;
  bool get sortAscending => _sortAscending;
  int get page => _page;
  int get size => _size;
  bool get includeDeleted => _includeDeleted;

  void updateSearch(String v) {
    _search = v;
    _page = 1;
    _debouncer.call(_load);
  }

  void updateFilters({bool? includeDeleted}) {
    if (includeDeleted != null) {
      _includeDeleted = includeDeleted;
    }
    _page = 1;
    _load();
  }

  void sortBy(String f) {
    if (_sortField == f) {
      _sortAscending = !_sortAscending;
    } else {
      _sortField = f;
      _sortAscending = true;
    }
    _page = 1;
    _load();
  }

  void goToPage(int p) {
    _page = p;
    _load();
  }

  void setSize(int s) {
    _size = s;
    _page = 1;
    _load();
  }

  Future<void> load() => _load();

  Future<void> _load() async {
    _status = LoadStatus.loading;
    _error = null;
    _selected.clear();
    notifyListeners();
    try {
      _result = await _repo.find(
        search: _search,
        sortField: _sortField,
        sortAscending: _sortAscending,
        page: _page,
        size: _size,
        includeDeleted: _includeDeleted,
      );
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Ошибка: $e';
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    if (_selected.isEmpty) return;
    await _repo.deleteMany(_selected.toList());
    _selected.clear();
    await _load();
  }

  Future<void> softDeleteSelected() async {
    if (_selected.isEmpty) return;
    for (final id in _selected.toList()) {
      await _repo.softDelete(id);
    }
    _selected.clear();
    await _load();
  }

  Future<void> restoreSelected() async {
    if (_selected.isEmpty) return;
    for (final id in _selected.toList()) {
      await _repo.restore(id);
    }
    _selected.clear();
    await _load();
  }

  Future<void> hardDeleteSelected() async {
    if (_selected.isEmpty) return;
    for (final id in _selected.toList()) {
      await _repo.hardDelete(id);
    }
    _selected.clear();
    await _load();
  }

  Future<Publisher?> findById(int id) => _repo.findById(id);

  Future<void> save(Publisher publisher) async {
    if (publisher.id == 0) {
      await _repo.create(publisher);
    } else {
      await _repo.update(publisher);
    }
    await _load();
  }

  Future<void> deletePublisher(int id) async {
    final books =
        await _bookRepo.find(publisherId: id, includeDeleted: true, size: 1);
    if (books.total > 0) {
      throw Exception(
          'Невозможно удалить: ${books.total} книг ссылаются на издательство');
    }
    await _repo.softDelete(id);
    await _load();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }
}
