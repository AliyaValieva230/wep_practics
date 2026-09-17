import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _requestAdminApi(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final dio = context.read<Dio>();
      final r = await dio.get('/users');
      messenger.showSnackBar(
        SnackBar(content: Text('OK: ${r.statusCode}')),
      );
    } on DioException catch (e) {
      final apiErr = e.error;
      final msg =
          apiErr is Exception ? apiErr.toString() : (e.message ?? 'Ошибка');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка: $msg'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Ошибка: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Администрирование'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${auth.user?.fullName ?? ""} • ${auth.user?.role.label ?? ""}',
              ),
            ),
          ),
          IconButton(
            tooltip: 'Выйти',
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(reason: 'Выход по кнопке'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            const Text(
              'Пользователи',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text('reader — Читатель'),
            ),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text('librarian — Библиотекарь'),
            ),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text('admin — Администратор'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Действия',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.restore),
                  label: const Text('Восстановить записи'),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('Физическое удаление'),
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Статистика'),
                ),
                FilledButton.icon(
                  onPressed: () => _requestAdminApi(context),
                  icon: const Icon(Icons.security),
                  label: const Text('Запрос к админ-API'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Перейти к разделам',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/books'),
                  icon: const Icon(Icons.library_books),
                  label: const Text('Книги'),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/authors'),
                  icon: const Icon(Icons.people_outline),
                  label: const Text('Авторы'),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/genres'),
                  icon: const Icon(Icons.category_outlined),
                  label: const Text('Жанры'),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/publishers'),
                  icon: const Icon(Icons.business_outlined),
                  label: const Text('Издательства'),
                ),
                FilledButton.icon(
                  onPressed: () => context.go('/readers'),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Читатели'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Вы вошли как ${auth.user?.fullName}',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
