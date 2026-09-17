import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wep_practics/core/api_exceptions.dart';
import 'package:wep_practics/models/book.dart';
import 'package:wep_practics/repositories/api_book_repository.dart';

void main() {
  group('ApiBookRepository', () {
    test('find возвращает PageResult', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockAdapter((options) async {
        return ResponseBody.fromString(
          '{"items":[{"id":1,"title":"Test","isbn":"123","year":2020,"pages":100,"publisherId":1,"authorIds":[],"genreIds":[],"copiesTotal":1,"copiesAvailable":1}],"page":1,"size":10,"total":1}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType]
          },
        );
      });
      final repo = ApiBookRepository(dio);
      final result = await repo.find();
      expect(result.total, 1);
      expect(result.items.first.title, 'Test');
    });

    test('422 → ValidationException', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.interceptors.add(InterceptorsWrapper(
        onResponse: (r, h) {
          if ((r.statusCode ?? 0) >= 400) {
            return h.reject(
                DioException(
                  requestOptions: r.requestOptions,
                  response: r,
                  error: mapHttpError(r.statusCode!, r.data),
                ),
                true);
          }
          return h.next(r);
        },
      ));
      dio.httpClientAdapter = _MockAdapter((_) async => ResponseBody.fromString(
            '{"message":"Ошибка","errors":{"isbn":"занят"}}',
            422,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          ));
      final repo = ApiBookRepository(dio);
      expect(
        () => repo.create(const Book(
            id: 0,
            title: 't',
            isbn: 'i',
            year: 2020,
            pages: 1,
            publisherId: 1,
            authorIds: [],
            genreIds: [],
            copiesTotal: 1,
            copiesAvailable: 1)),
        throwsA(isA<ValidationException>()),
      );
    });

    test('connectionError → NetworkException', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockAdapter((_) async => throw DioException(
            requestOptions: RequestOptions(path: '/'),
            type: DioExceptionType.connectionError,
          ));
      final repo = ApiBookRepository(dio);
      expect(() => repo.find(), throwsA(isA<NetworkException>()));
    });

    test('404 → NotFoundException', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockAdapter((_) async => ResponseBody.fromString(
            '{"message":"Нет"}',
            404,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          ));
      final repo = ApiBookRepository(dio);
      expect(() => repo.findById(999), throwsA(isA<NotFoundException>()));
    });

    test('deleteMany возвращает количество', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://test'));
      dio.httpClientAdapter = _MockAdapter((_) async => ResponseBody.fromString(
            '{"deleted":3}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType]
            },
          ));
      final repo = ApiBookRepository(dio);
      expect(await repo.deleteMany([1, 2, 3]), 3);
    });
  });
}

class _MockAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions) handler;
  _MockAdapter(this.handler);
  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) =>
      handler(options);
  @override
  void close({bool force = false}) {}
}
