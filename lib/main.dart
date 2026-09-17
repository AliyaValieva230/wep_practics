import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/connectivity_notifier.dart';
import 'core/router.dart';
import 'repositories/api_author_repository.dart';
import 'repositories/api_book_repository.dart';
import 'repositories/api_genre_repository.dart';
import 'repositories/api_publisher_repository.dart';
import 'repositories/api_reader_repository.dart';
import 'repositories/api_auth_repository.dart';
import 'repositories/author_repository.dart';
import 'repositories/book_repository.dart';
import 'repositories/genre_repository.dart';
import 'repositories/publisher_repository.dart';
import 'repositories/reader_repository.dart';
import 'repositories/auth_repository.dart';
import 'state/auth_notifier.dart';
import 'state/book_list_notifier.dart';
import 'state/author_list_notifier.dart';
import 'state/genre_list_notifier.dart';
import 'state/publisher_list_notifier.dart';
import 'state/reader_list_notifier.dart';
import 'widgets/activity_detector.dart';
import 'widgets/session_warning_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  final authDio = buildDio();
  final AuthRepository authRepo = ApiAuthRepository(authDio);
  final auth = AuthNotifier(prefs, authRepo);
  await auth.bootstrap();

  final mainDio = buildDio(
    tokenProvider: () => auth.accessToken,
    onRefresh: auth.refreshTokens,
    onLogout: () => auth.logout(reason: 'Сессия истекла'),
  );

  final BookRepository bookRepo = ApiBookRepository(mainDio);
  final AuthorRepository authorRepo = ApiAuthorRepository(mainDio);
  final GenreRepository genreRepo = ApiGenreRepository(mainDio);
  final PublisherRepository publisherRepo = ApiPublisherRepository(mainDio);
  final ReaderRepository readerRepo = ApiReaderRepository(mainDio);

  final router = buildRouter(auth);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(value: auth),
        ChangeNotifierProvider<ConnectivityNotifier>(
          create: (_) => ConnectivityNotifier(mainDio),
        ),
        Provider<Dio>.value(value: mainDio),
        Provider<BookRepository>.value(value: bookRepo),
        Provider<AuthorRepository>.value(value: authorRepo),
        Provider<GenreRepository>.value(value: genreRepo),
        Provider<PublisherRepository>.value(value: publisherRepo),
        Provider<ReaderRepository>.value(value: readerRepo),
        ChangeNotifierProvider(create: (_) => BookListNotifier(bookRepo)),
        ChangeNotifierProvider(create: (_) => AuthorListNotifier(authorRepo)),
        ChangeNotifierProvider(create: (_) => GenreListNotifier(genreRepo)),
        ChangeNotifierProvider(
          create: (_) => PublisherListNotifier(publisherRepo, bookRepo),
        ),
        ChangeNotifierProvider(create: (_) => ReaderListNotifier(readerRepo)),
      ],
      child: LibraryApp(router: router),
    ),
  );
}

class LibraryApp extends StatelessWidget {
  final GoRouter router;
  const LibraryApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final conn = context.watch<ConnectivityNotifier>();

    return ActivityDetector(
      onActivity: auth.noteActivity,
      child: MaterialApp.router(
        title: 'Библиотека',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        routerConfig: router,
        builder: (context, child) {
          final width = MediaQuery.sizeOf(context).width;
          final scale = _uiScaleForWidth(width);
          final base = MediaQuery.of(context);

          return MediaQuery(
            data: base.copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Column(
                children: [
                  if (!conn.isOnline)
                    MaterialBanner(
                      backgroundColor: Colors.red.shade100,
                      leading: const Icon(Icons.wifi_off),
                      content: const Text(
                        'Нет соединения с сервером. '
                        'Повторная попытка выполняется автоматически.',
                      ),
                      actions: const [SizedBox.shrink()],
                    ),
                  const SessionWarningBanner(),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Масштаб интерфейса в зависимости от ширины окна.
  /// На телефоне 1.0, на мониторе 1.25, на 4К — 1.5.
  static double _uiScaleForWidth(double width) {
    if (width < 600) return 1.0;
    if (width < 1000) return 1.0;
    if (width < 1400) return 1.15;
    if (width < 1800) return 1.25;
    return 1.4;
  }
}