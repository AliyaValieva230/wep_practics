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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Text(
              '${auth.user?.fullName ?? ""} • ${auth.user?.role.label ?? ""}',
              overflow: TextOverflow.ellipsis,
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

  static const _destinations = <({IconData icon, String label})>[
    (icon: Icons.menu_book, label: 'Книги'),
    (icon: Icons.people_outline, label: 'Авторы'),
    (icon: Icons.category_outlined, label: 'Жанры'),
    (icon: Icons.business_outlined, label: 'Издательства'),
    (icon: Icons.person_outline, label: 'Читатели'),
  ];

  @override
  Widget build(BuildContext context) {
    final size = screenSizeOf(context);
    final role = context.watch<AuthNotifier>().user?.role;

    if (size == ScreenSize.compact) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex.clamp(0, _destinations.length - 1),
          onDestinationSelected: onDestinationSelected,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(icon: Icon(d.icon), label: d.label),
          ],
        ),
      );
    }

    final extended = size == ScreenSize.expanded;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex.clamp(0, _destinations.length - 1),
            onDestinationSelected: onDestinationSelected,
            extended: extended,
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Tooltip(
                message: 'Кабинет',
                child: IconButton(
                  icon: const Icon(Icons.home_outlined),
                  onPressed: () => context.go(role?.homeRoute ?? '/'),
                ),
              ),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
