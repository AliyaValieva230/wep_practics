import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/forbidden_screen.dart';
import '../screens/reader_dashboard_screen.dart' deferred as reader;
import '../screens/librarian_dashboard_screen.dart' deferred as librarian;
import '../screens/admin_dashboard_screen.dart' deferred as admin;
import '../screens/book_list_screen.dart';
import '../screens/book_form_screen.dart';
import '../screens/book_detail_screen.dart';
import '../screens/author_list_screen.dart';
import '../screens/author_form_screen.dart';
import '../screens/author_detail_screen.dart';
import '../screens/genre_list_screen.dart';
import '../screens/genre_form_screen.dart';
import '../screens/publisher_list_screen.dart';
import '../screens/publisher_form_screen.dart';
import '../screens/reader_list_screen.dart';
import '../screens/reader_form_screen.dart';
import '../screens/reader_detail_screen.dart';
import '../screens/not_found_screen.dart';
import '../state/auth_notifier.dart';
import 'role.dart';

GoRouter buildRouter(AuthNotifier auth) {
  const publicPaths = {'/login', '/register'};

  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      final loggedIn = auth.isAuthenticated;
      final target = state.uri.path;
      final isPublic = publicPaths.contains(target);

      if (!loggedIn) {
        if (isPublic) return null;
        final from = Uri.encodeComponent(state.uri.toString());
        return '/login?from=$from';
      }

      if (isPublic) {
        final from = state.uri.queryParameters['from'];
        if (from == null || from.isEmpty || publicPaths.contains(from)) {
          return auth.user!.role.homeRoute;
        }
        return from;
      }

      if (target == '/' || target.isEmpty) {
        return auth.user!.role.homeRoute;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const _RootRedirect(),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/forbidden', builder: (_, __) => const ForbiddenScreen()),
      GoRoute(
        path: '/my-loans',
        redirect: (_, __) => auth.user?.role == Role.reader ? null : '/forbidden',
        builder: (_, __) => FutureBuilder(
          future: reader.loadLibrary(),
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return reader.ReaderDashboardScreen();
          },
        ),
      ),
      GoRoute(
        path: '/librarian',
        redirect: (_, __) =>
            auth.user?.role == Role.librarian ? null : '/forbidden',
        builder: (_, __) => FutureBuilder(
          future: librarian.loadLibrary(),
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return librarian.LibrarianDashboardScreen();
          },
        ),
      ),
      GoRoute(
        path: '/admin',
        redirect: (_, __) => auth.user?.role == Role.admin ? null : '/forbidden',
        builder: (_, __) => FutureBuilder(
          future: admin.loadLibrary(),
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return admin.AdminDashboardScreen();
          },
        ),
      ),
      GoRoute(path: '/books', builder: (_, __) => const BookListScreen()),
      GoRoute(
        path: '/books/new',
        redirect: (_, __) => auth.has(Role.librarian) ? null : '/forbidden',
        builder: (_, __) => const BookFormScreen(),
      ),
      GoRoute(
        path: '/books/:id/edit',
        redirect: (_, __) => auth.has(Role.librarian) ? null : '/forbidden',
        builder: (_, s) =>
            BookFormScreen(id: int.tryParse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/books/:id',
        builder: (_, s) =>
            BookDetailScreen(id: int.tryParse(s.pathParameters['id']!)!),
      ),
      GoRoute(path: '/authors', builder: (_, __) => const AuthorListScreen()),
      GoRoute(
        path: '/authors/new',
        redirect: (_, __) => auth.has(Role.librarian) ? null : '/forbidden',
        builder: (_, __) => const AuthorFormScreen(),
      ),
      GoRoute(
        path: '/authors/:id/edit',
        redirect: (_, __) => auth.has(Role.librarian) ? null : '/forbidden',
        builder: (_, s) =>
            AuthorFormScreen(id: int.tryParse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/authors/:id',
        builder: (_, s) =>
            AuthorDetailScreen(id: int.tryParse(s.pathParameters['id']!)!),
      ),
      GoRoute(path: '/genres', builder: (_, __) => const GenreListScreen()),
      GoRoute(
        path: '/genres/new',
        redirect: (_, __) => auth.has(Role.librarian) ? null : '/forbidden',
        builder: (_, __) => const GenreFormScreen(),
      ),
      GoRoute(
        path: '/genres/:id/edit',
        redirect: (_, __) => auth.has(Role.librarian) ? null : '/forbidden',
        builder: (_, s) =>
            GenreFormScreen(id: int.tryParse(s.pathParameters['id']!)),
      ),
      GoRoute(
          path: '/publishers',
          builder: (_, __) => const PublisherListScreen()),
      GoRoute(
        path: '/publishers/new',
        redirect: (_, __) => auth.has(Role.librarian) ? null : '/forbidden',
        builder: (_, __) => const PublisherFormScreen(),
      ),
      GoRoute(
        path: '/publishers/:id/edit',
        redirect: (_, __) => auth.has(Role.librarian) ? null : '/forbidden',
        builder: (_, s) =>
            PublisherFormScreen(id: int.tryParse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/readers', builder: (_, __) => const ReaderListScreen()),
      GoRoute(
        path: '/readers/new',
        redirect: (_, __) => auth.has(Role.librarian) ? null : '/forbidden',
        builder: (_, __) => const ReaderFormScreen(),
      ),
      GoRoute(
        path: '/readers/:id/edit',
        redirect: (_, __) => auth.has(Role.librarian) ? null : '/forbidden',
        builder: (_, s) =>
            ReaderFormScreen(id: int.tryParse(s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/readers/:id',
        builder: (_, s) =>
            ReaderDetailScreen(id: int.tryParse(s.pathParameters['id']!)!),
      ),
    ],
    errorBuilder: (_, s) => NotFoundScreen(location: s.uri.toString()),
  );
}

class _RootRedirect extends StatelessWidget {
  const _RootRedirect();
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}