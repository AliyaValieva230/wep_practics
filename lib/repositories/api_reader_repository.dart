import 'package:dio/dio.dart';
import '../models/reader.dart';
import '../models/page_result.dart';
import '../core/api_exceptions.dart';
import 'reader_repository.dart';

class ApiReaderRepository implements ReaderRepository {
  final Dio _dio;
  ApiReaderRepository(this._dio);

  @override
  Future<PageResult<Reader>> find({
    String search = '',
    String sortField = 'lastName',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  }) =>
      guard(() async {
        final response = await _dio.get('/readers', queryParameters: {
          if (search.trim().isNotEmpty) 'search': search.trim(),
          'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
          'page': page,
          'size': size,
          if (includeDeleted) 'includeDeleted': true,
        });

        final data = response.data as Map<String, dynamic>;
        return PageResult(
          items: (data['items'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Reader.fromJson)
              .toList(),
          page: data['page'] as int? ?? 1,
          size: data['size'] as int? ?? size,
          total: data['total'] as int? ?? 0,
        );
      });

  @override
  Future<Reader?> findById(int id) => guard(() async {
        final response = await _dio.get('/readers/$id');
        return Reader.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Reader> create(Reader reader) => guard(() async {
        final response = await _dio.post('/readers', data: {
          'firstName': reader.firstName,
          'lastName': reader.lastName,
          'middleName': reader.middleName,
          'email': reader.email,
          if (reader.card != null)
            'card': {
              'barcode': reader.card!.barcode,
              'issuedAt': reader.card!.issuedAt.toIso8601String(),
              'expiresAt': reader.card!.expiresAt.toIso8601String(),
              'isActive': reader.card!.isActive,
            },
        });
        return Reader.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<Reader> update(Reader reader) => guard(() async {
        final response = await _dio.put('/readers/${reader.id}', data: {
          'firstName': reader.firstName,
          'lastName': reader.lastName,
          'middleName': reader.middleName,
          'email': reader.email,
          if (reader.card != null)
            'card': {
              'barcode': reader.card!.barcode,
              'issuedAt': reader.card!.issuedAt.toIso8601String(),
              'expiresAt': reader.card!.expiresAt.toIso8601String(),
              'isActive': reader.card!.isActive,
            },
        });
        return Reader.fromJson(response.data as Map<String, dynamic>);
      });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/readers/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/readers/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/readers/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
        final response =
            await _dio.post('/readers/bulk-delete', data: {'ids': ids});
        return (response.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
      });

  @override
  bool isEmailUnique(String email, {int? excludeId}) {
    return true;
  }
}
