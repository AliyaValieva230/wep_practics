import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

class ReaderDashboardScreen extends StatelessWidget {
  const ReaderDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Кабинет читателя'),
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
              'Мои выдачи',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.book_outlined),
              title: Text('«Война и мир»'),
              subtitle: Text('Вернуть до 01.10.2026'),
            ),
            const ListTile(
              leading: Icon(Icons.book_outlined),
              title: Text('«Мастер и Маргарита»'),
              subtitle: Text('Вернуть до 15.10.2026'),
            ),
            const SizedBox(height: 24),
            const Text(
              'Продление срока',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Продлить «Война и мир» на 14 дней — доступно.'),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/books'),
                  icon: const Icon(Icons.library_books),
                  label: const Text('Каталог книг'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
