import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return Scaffold(
      appBar: AppBar(title: const Text('Доступ запрещён')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 80, color: Colors.orange.shade700),
            const SizedBox(height: 16),
            const Text('Недостаточно прав для этой страницы',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            if (auth.user != null)
              Text('Роль: ${auth.user!.role.label}',
                  style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final home = auth.user?.role.homeRoute ?? '/login';
                context.go(home);
              },
              child: const Text('На главную'),
            ),
          ],
        ),
      ),
    );
  }
}
