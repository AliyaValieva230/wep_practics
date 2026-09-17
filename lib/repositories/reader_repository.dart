import '../models/reader.dart';
import '../models/page_result.dart';

abstract interface class ReaderRepository {
  Future<PageResult<Reader>> find({
    String search = '',
    String sortField = 'lastName',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  });
  Future<Reader?> findById(int id);
  Future<Reader> create(Reader reader);
  Future<Reader> update(Reader reader);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
  bool isEmailUnique(String email, {int? excludeId});
}
