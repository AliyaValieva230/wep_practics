import 'package:dio/dio.dart';
import '../models/author.dart';
import '../models/page_result.dart';
import '../core/api_exceptions.dart';
import 'author_repository.dart';

class ApiAuthorRepository implements AuthorRepository {
  final Dio _dio;
  ApiAuthorRepository(this._dio);

  @override
  Future<PageResult<Author>> find({
    String search = '',
    String? country,
    String sortField = 'lastName',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  }) =>
      guard(() async {
        final response = await _dio.get('/authors', queryParameters: {
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (country != null && country.isNotEmpty) 'country': country,
          'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
          'page': page,
          'size': size,
          if (includeDeleted) 'includeDeleted': true,
        });

        final data = response.data as Map<String, dynamic>;
        return PageResult(
          items: (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Author.fromJson)
              .toList(),
          page: data['page'] as int? ?? 1,
          size: data['size'] as int? ?? size,
          total: data['total'] as int? ?? 0,
        );
      });

  @override
  Future<Author?> findById(int id) => guard(() async {
        final response = await _dio.get('/authors/$id');
        return Author.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Author> create(Author author) => guard(() async {
        final response = await _dio.post('/authors', data: {
          'firstName': author.firstName,
          'lastName': author.lastName,
          'middleName': author.middleName,
          'country': author.country,
        });
        return Author.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Author> update(Author author) => guard(() async {
        final response = await _dio.put('/authors/${author.id}', data: {
          'firstName': author.firstName,
          'lastName': author.lastName,
          'middleName': author.middleName,
          'country': author.country,
        });
        return Author.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/authors/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/authors/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/authors/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response =
            await _dio.post('/authors/bulk-delete', data: {'ids': ids});
        return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });
}
