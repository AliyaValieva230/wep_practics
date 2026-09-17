import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/page_result.dart';
import '../repositories/book_repository.dart';
import '../core/debounce.dart';
import '../core/api_exceptions.dart';

enum LoadStatus { idle, loading, success, error }

class BookListNotifier extends ChangeNotifier {
  final BookRepository _repo;
  BookListNotifier(this._repo);

  String _search = '';
  int? _genreId;
  int? _publisherId;
  int? _yearFrom;
  int? _yearTo;
  String _sortField = 'title';
  bool _sortAscending = true;
  int _page = 1;
  int _size = 10;
  bool _includeDeleted = false;

  LoadStatus _status = LoadStatus.idle;
  String? _error;
  PageResult<Book> _result = PageResult.empty();
  final Set<int> _selected = {};
  final Debouncer _debouncer = Debouncer();
  CancelToken? _cancelToken;

  LoadStatus get status => _status;
  String? get error => _error;
  PageResult<Book> get result => _result;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;
  String get search => _search;
  int? get genreId => _genreId;
  int? get publisherId => _publisherId;
  int? get yearFrom => _yearFrom;
  int? get yearTo => _yearTo;
  String get sortField => _sortField;
  bool get sortAscending => _sortAscending;
  int get page => _page;
  int get size => _size;
  bool get includeDeleted => _includeDeleted;

  void updateSearch(String value) {
    _search = value;
    _page = 1;
    _cancelToken?.cancel('Новый поиск');
    _cancelToken = CancelToken();
    _debouncer.call(() => _load(_cancelToken));
  }

  void updateFilters({
    int? genreId,
    int? publisherId,
    int? yearFrom,
    int? yearTo,
    bool? includeDeleted,
  }) {
    if (genreId != null) _genreId = genreId;
    if (publisherId != null) _publisherId = publisherId;
    if (yearFrom != null) _yearFrom = yearFrom;
    if (yearTo != null) _yearTo = yearTo;
    if (includeDeleted != null) _includeDeleted = includeDeleted;
    _page = 1;
    _load();
  }

  void sortBy(String field) {
    if (_sortField == field) {
      _sortAscending = !_sortAscending;
    } else {
      _sortField = field;
      _sortAscending = true;
    }
    _page = 1;
    _load();
  }

  void goToPage(int page) {
    _page = page;
    _load();
  }

  void setSize(int size) {
    _size = size;
    _page = 1;
    _load();
  }

  Future<void> load() => _load();

  Future<void> _load([CancelToken? token]) async {
    _status = LoadStatus.loading;
    _error = null;
    _selected.clear();
    notifyListeners();
    try {
      _result = await _repo.find(
        search: _search,
        genreId: _genreId,
        publisherId: _publisherId,
        yearFrom: _yearFrom,
        yearTo: _yearTo,
        sortField: _sortField,
        sortAscending: _sortAscending,
        page: _page,
        size: _size,
        includeDeleted: _includeDeleted,
        cancelToken: token,
      );
      _status = LoadStatus.success;
    } on NetworkException catch (e) {
      if (token?.isCancelled ?? false) return;
      _error = e.message;
      _status = LoadStatus.error;
    } on ApiException catch (e) {
      _error = e.message;
      _status = LoadStatus.error;
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

  Future<Book?> findById(int id) => _repo.findById(id);

  Future<void> save(Book book) async {
    if (book.id == 0) {
      await _repo.create(book);
    } else {
      await _repo.update(book);
    }
    await _load();
  }

  bool isIsbnUnique(String isbn, {int? excludeId}) => true;

  @override
  void dispose() {
    _cancelToken?.cancel('Notifier disposed');
    _debouncer.dispose();
    super.dispose();
  }
}
