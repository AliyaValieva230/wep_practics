import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../state/auth_notifier.dart';

class AuthActions extends StatelessWidget {
  const AuthActions({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 180),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${auth.user?.fullName ?? ""} • ${auth.user?.role.label ?? ""}',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        Tooltip(
          message: 'Выйти',
          child: IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.logout(reason: 'Выход по кнопке'),
          ),
        ),
      ],
    );
  }
}

class AppScaffold extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const AppScaffold({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  static const _labels = <String>[
    'Книги',
    'Авторы',
    'Жанры',
    'Издательства',
    'Читатели',
  ];

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    final role = context.watch<AuthNotifier>().user?.role;

    // Узкий экран: своя панель без иконок, только текст
    if (size == ScreenSize.compact) {
      return Scaffold(
        body: child,
        bottomNavigationBar: _TextOnlyNavBar(
          labels: _labels,
          selectedIndex: selectedIndex,
          onSelected: onDestinationSelected,
        ),
      );
    }

    // Средний и широкий экран: боковой список без иконок
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 200,
            color: Theme.of(context).colorScheme.surface,
            child: ListView(
              children: [
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Кабинет'),
                  onTap: () => context.go(role?.homeRoute ?? '/'),
                ),
                const Divider(),
                for (var i = 0; i < _labels.length; i++)
                  ListTile(
                    title: Text(_labels[i]),
                    selected: i == selectedIndex,
                    selectedTileColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    onTap: () => onDestinationSelected(i),
                  ),
              ],
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Нижняя панель только с текстом — без иконок.
class _TextOnlyNavBar extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _TextOnlyNavBar({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TextButton(
                    onPressed: () => onSelected(i),
                    style: TextButton.styleFrom(
                      foregroundColor: i == selectedIndex
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      backgroundColor: i == selectedIndex
                          ? scheme.primaryContainer
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontWeight: i == selectedIndex
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
