import 'package:dio/dio.dart';
import '../models/book.dart';
import '../models/page_result.dart';
import '../core/api_exceptions.dart';
import 'book_repository.dart';

class ApiBookRepository implements BookRepository {
  final Dio _dio;
  ApiBookRepository(this._dio);

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
  }) =>
      guard(() async {
        final response = await _dio.get('/books',
            queryParameters: {
              '__delay': 1500, // ← ВРЕМЕННО для скриншота (потом удалить)
              if (search.trim().isNotEmpty) 'search': search.trim(),
              if (genreId != null) 'genreId': genreId,
              if (publisherId != null) 'publisherId': publisherId,
              if (yearFrom != null) 'yearFrom': yearFrom,
              if (yearTo != null) 'yearTo': yearTo,
              'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
              'page': page,
              'size': size,
              if (includeDeleted) 'includeDeleted': true,
            },
            cancelToken: cancelToken);

        final data = response.data as Map<String, dynamic>;
        return PageResult(
          items: (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Book.fromJson)
              .toList(),
          page: data['page'] as int? ?? 1,
          size: data['size'] as int? ?? size,
          total: data['total'] as int? ?? 0,
        );
      });

  @override
  Future<Book?> findById(int id) => guard(() async {
        final response = await _dio.get('/books/$id');
        return Book.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Book> create(Book book) => guard(() async {
        final response = await _dio.post('/books', data: {
          'title': book.title,
          'isbn': book.isbn,
          'year': book.year,
          'pages': book.pages,
          'publisherId': book.publisherId,
          'authorIds': book.authorIds,
          'genreIds': book.genreIds,
          'copiesTotal': book.copiesTotal,
          'copiesAvailable': book.copiesAvailable,
        });
        return Book.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Book> update(Book book) => guard(() async {
        final response = await _dio.put('/books/${book.id}', data: {
          'title': book.title,
          'isbn': book.isbn,
          'year': book.year,
          'pages': book.pages,
          'publisherId': book.publisherId,
          'authorIds': book.authorIds,
          'genreIds': book.genreIds,
          'copiesTotal': book.copiesTotal,
          'copiesAvailable': book.copiesAvailable,
        });
        return Book.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/books/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/books/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/books/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response =
            await _dio.post('/books/bulk-delete', data: {'ids': ids});
        return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });
}
