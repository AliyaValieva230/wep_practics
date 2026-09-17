import 'package:dio/dio.dart';
import '../models/book.dart';
import '../models/page_result.dart';

abstract interface class BookRepository {
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
  });
  Future<Book?> findById(int id);
  Future<Book> create(Book book);
  Future<Book> update(Book book);
  Future<void> softDelete(int id);
  Future<void> hardDelete(int id);
  Future<void> restore(int id);
  Future<int> deleteMany(List<int> ids);
}
