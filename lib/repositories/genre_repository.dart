import '../models/genre.dart';
import '../models/page_result.dart';

abstract interface class GenreRepository {
  Future<PageResult<Genre>> find({
    String search = '',
    String sortField = 'name',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  });
  Future<Genre?> findById(int id);
  Future<Genre> create(Genre genre);
  Future<Genre> update(Genre genre);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
