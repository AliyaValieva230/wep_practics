import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

class LibrarianDashboardScreen extends StatelessWidget {
  const LibrarianDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Рабочее место библиотекаря'),
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
              'Очередь выдач',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.book_outlined),
              title: Text('#1024 Петров И. — «Преступление и наказание»'),
            ),
            const ListTile(
              leading: Icon(Icons.book_outlined),
              title: Text('#1025 Сидорова М. — «Анна Каренина»'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Справочники и работа с читателями',
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
            const Text(
              'Оформление / закрытие выдач, работа с читателями.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
