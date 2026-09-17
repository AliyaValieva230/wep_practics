import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wep_practics/core/role.dart';
import 'package:wep_practics/models/app_user.dart';
import 'package:wep_practics/models/author.dart';
import 'package:wep_practics/models/book.dart';
import 'package:wep_practics/models/genre.dart';
import 'package:wep_practics/models/page_result.dart';
import 'package:wep_practics/models/publisher.dart';
import 'package:wep_practics/repositories/auth_repository.dart';
import 'package:wep_practics/repositories/author_repository.dart';
import 'package:wep_practics/repositories/book_repository.dart';
import 'package:wep_practics/repositories/genre_repository.dart';
import 'package:wep_practics/repositories/publisher_repository.dart';
import 'package:wep_practics/screens/author_list_screen.dart';
import 'package:wep_practics/screens/book_form_screen.dart';
import 'package:wep_practics/screens/book_list_screen.dart';
import 'package:wep_practics/state/auth_notifier.dart';
import 'package:wep_practics/state/author_list_notifier.dart';
import 'package:wep_practics/state/book_list_notifier.dart';
import 'package:wep_practics/state/genre_list_notifier.dart';
import 'package:wep_practics/state/publisher_list_notifier.dart';

class _FakeAuthRepo implements AuthRepository {
  final AppUser user;
  _FakeAuthRepo(this.user);

  @override
  Future<AuthResult> login(String username, String password) async =>
      AuthResult(accessToken: 'a', refreshToken: 'r', user: user);

  @override
  Future<AuthResult> register({
    required String username,
    required String fullName,
    required String password,
  }) async =>
      AuthResult(accessToken: 'a', refreshToken: 'r', user: user);

  @override
  Future<AppUser> me() async => user;

  @override
  Future<AuthResult> refresh(String refreshToken) async =>
      AuthResult(accessToken: 'a', refreshToken: refreshToken, user: user);

  @override
  Future<void> logout() async {}
}

Future<AuthNotifier> _makeAuth(Role role) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final user = AppUser(
    id: 1,
    username: role.name,
    fullName: 'Test ${role.label}',
    role: role,
  );
  final auth = AuthNotifier(prefs, _FakeAuthRepo(user));
  await auth.login('u', 'p');
  return auth;
}

class _FakeBookRepo implements BookRepository {
  final List<Book> items;
  final Object? error;
  final Completer<void>? gate;
  _FakeBookRepo({this.items = const [], this.error, this.gate});

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
    dynamic cancelToken,
  }) async {
    if (gate != null) {
      await gate!.future;
    }
    if (error != null) {
      throw error!;
    }
    return PageResult(items: items, page: 1, size: 10, total: items.length);
  }

  @override
  Future<Book?> findById(int id) async {
    for (final b in items) {
      if (b.id == id) return b;
    }
    return null;
  }

  @override
  Future<Book> create(Book b) async => b;
  @override
  Future<Book> update(Book b) async => b;
  @override
  Future<void> softDelete(int id) async {}
  @override
  Future<void> hardDelete(int id) async {}
  @override
  Future<void> restore(int id) async {}
  @override
  Future<int> deleteMany(List<int> ids) async => 0;
}

class _FakeAuthorRepo implements AuthorRepository {
  @override
  Future<PageResult<Author>> find({
    String search = '',
    String? country,
    String sortField = 'lastName',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  }) async =>
      const PageResult(items: [], page: 1, size: 10, total: 0);

  @override
  Future<Author?> findById(int id) async => null;
  @override
  Future<Author> create(Author a) async => a;
  @override
  Future<Author> update(Author a) async => a;
  @override
  Future<void> softDelete(int id) async {}
  @override
  Future<void> hardDelete(int id) async {}
  @override
  Future<void> restore(int id) async {}
  @override
  Future<int> deleteMany(List<int> ids) async => 0;
}

class _FakeGenreRepo implements GenreRepository {
  @override
  Future<PageResult<Genre>> find({
    String search = '',
    String sortField = 'name',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  }) async =>
      const PageResult(items: [], page: 1, size: 10, total: 0);
  @override
  Future<Genre?> findById(int id) async => null;
  @override
  Future<Genre> create(Genre g) async => g;
  @override
  Future<Genre> update(Genre g) async => g;
  @override
  Future<void> softDelete(int id) async {}
  @override
  Future<void> hardDelete(int id) async {}
  @override
  Future<void> restore(int id) async {}
  @override
  Future<int> deleteMany(List<int> ids) async => 0;
}

class _FakePublisherRepo implements PublisherRepository {
  @override
  Future<PageResult<Publisher>> find({
    String search = '',
    String sortField = 'name',
    bool sortAscending = true,
    int page = 1,
    int size = 10,
    bool includeDeleted = false,
  }) async =>
      const PageResult(items: [], page: 1, size: 10, total: 0);
  @override
  Future<Publisher?> findById(int id) async => null;
  @override
  Future<Publisher> create(Publisher p) async => p;
  @override
  Future<Publisher> update(Publisher p) async => p;
  @override
  Future<void> softDelete(int id) async {}
  @override
  Future<void> hardDelete(int id) async {}
  @override
  Future<void> restore(int id) async {}
  @override
  Future<int> deleteMany(List<int> ids) async => 0;
}

Widget _wrap(
  Widget child, {
  required AuthNotifier auth,
  List<SingleChildWidget> extra = const [],
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthNotifier>.value(value: auth),
      ...extra,
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('BookList: состояние загрузки показывает индикатор',
      (tester) async {
    final auth = await _makeAuth(Role.reader);
    final gate = Completer<void>();
    final repo = _FakeBookRepo(items: const [], gate: gate);
    final notifier = BookListNotifier(repo);
    notifier.load();

    try {
      await tester.pumpWidget(_wrap(
        const BookListScreen(),
        auth: auth,
        extra: [
          ChangeNotifierProvider<BookListNotifier>.value(value: notifier),
        ],
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      gate.complete();
      await tester.pump();
      await tester.pump();
    } finally {
      auth.dispose();
      notifier.dispose();
    }
  });

  testWidgets('BookList: пустой результат показывает текст', (tester) async {
    final auth = await _makeAuth(Role.reader);
    final repo = _FakeBookRepo(items: const []);
    final notifier = BookListNotifier(repo);

    try {
      await tester.pumpWidget(_wrap(
        const BookListScreen(),
        auth: auth,
        extra: [
          ChangeNotifierProvider<BookListNotifier>.value(value: notifier),
        ],
      ));
      await notifier.load();
      await tester.pumpAndSettle();

      expect(find.text('Книг не найдено'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    } finally {
      auth.dispose();
      notifier.dispose();
    }
  });

  testWidgets('BookList: ошибка показывает кнопку "Повторить"', (tester) async {
    final auth = await _makeAuth(Role.reader);
    final repo = _FakeBookRepo(error: Exception('boom'));
    final notifier = BookListNotifier(repo);

    try {
      await tester.pumpWidget(_wrap(
        const BookListScreen(),
        auth: auth,
        extra: [
          ChangeNotifierProvider<BookListNotifier>.value(value: notifier),
        ],
      ));
      await notifier.load();
      await tester.pumpAndSettle();

      expect(find.text('Повторить'), findsOneWidget);
    } finally {
      auth.dispose();
      notifier.dispose();
    }
  });

  testWidgets('BookForm: пустая форма не отправляется', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = await _makeAuth(Role.librarian);
    final bookNotifier = BookListNotifier(_FakeBookRepo());
    final authorNotifier = AuthorListNotifier(_FakeAuthorRepo());
    final genreNotifier = GenreListNotifier(_FakeGenreRepo());
    final publisherNotifier =
        PublisherListNotifier(_FakePublisherRepo(), _FakeBookRepo());

    try {
      await tester.pumpWidget(_wrap(
        const BookFormScreen(),
        auth: auth,
        extra: [
          ChangeNotifierProvider<BookListNotifier>.value(value: bookNotifier),
          ChangeNotifierProvider<AuthorListNotifier>.value(
              value: authorNotifier),
          ChangeNotifierProvider<GenreListNotifier>.value(value: genreNotifier),
          ChangeNotifierProvider<PublisherListNotifier>.value(
              value: publisherNotifier),
        ],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Создать'));
      await tester.pump();

      expect(find.text('Поле обязательно'), findsWidgets);
    } finally {
      auth.dispose();
      bookNotifier.dispose();
      authorNotifier.dispose();
      genreNotifier.dispose();
      publisherNotifier.dispose();
    }
  });

  testWidgets('AuthorList: кнопка "Добавить" скрыта для reader',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = await _makeAuth(Role.reader);
    final notifier = AuthorListNotifier(_FakeAuthorRepo());

    try {
      await tester.pumpWidget(_wrap(
        const AuthorListScreen(),
        auth: auth,
        extra: [
          ChangeNotifierProvider<AuthorListNotifier>.value(value: notifier),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsNothing);
    } finally {
      auth.dispose();
      notifier.dispose();
    }
  });

  testWidgets('AuthorList: кнопка "Добавить" показана для librarian',
      (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final auth = await _makeAuth(Role.librarian);
    final notifier = AuthorListNotifier(_FakeAuthorRepo());

    try {
      await tester.pumpWidget(_wrap(
        const AuthorListScreen(),
        auth: auth,
        extra: [
          ChangeNotifierProvider<AuthorListNotifier>.value(value: notifier),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    } finally {
      auth.dispose();
      notifier.dispose();
    }
  });
}
