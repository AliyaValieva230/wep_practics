import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/role.dart';
import '../state/auth_notifier.dart';
import '../state/author_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/entity_table.dart';
import '../widgets/entity_card_list.dart';
import '../models/author.dart';

class AuthorListScreen extends StatefulWidget {
  const AuthorListScreen({super.key});
  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final canEdit = context.watch<AuthNotifier>().has(Role.librarian);
    return AppScaffold(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
        if (index == 0) {
          context.go('/books');
        } else if (index == 1) {
          context.go('/authors');
        } else if (index == 2) {
          context.go('/genres');
        } else if (index == 3) {
          context.go('/publishers');
        } else {
          context.go('/readers');
        }
      },
      child: Consumer<AuthorListNotifier>(
        builder: (context, notifier, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Авторы'),
              actions: [
                const AuthActions(),
                IconButton(
                  icon: Icon(notifier.includeDeleted
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => notifier.updateFilters(
                      includeDeleted: !notifier.includeDeleted),
                ),
                if (notifier.hasSelection)
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'softDelete') {
                        await notifier.softDeleteSelected();
                      } else if (value == 'restore') {
                        await notifier.restoreSelected();
                      } else if (value == 'hardDelete') {
                        await notifier.hardDeleteSelected();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                          value: 'softDelete',
                          child: Text('Логически удалить')),
                      PopupMenuItem(
                          value: 'restore', child: Text('Восстановить')),
                      PopupMenuItem(
                          value: 'hardDelete',
                          child: Text('Физически удалить')),
                    ],
                  ),
                if (canEdit)
                  IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => context.go('/authors/new')),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Поиск по фамилии, имени, стране',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: notifier.updateSearch,
                  ),
                ),
              ),
            ),
            body: _buildBody(context, notifier, canEdit),
            bottomNavigationBar: _buildPagination(context, notifier),
          );
        },
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AuthorListNotifier notifier, bool canEdit) {
    if (notifier.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifier.status == LoadStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ошибка: ${notifier.error}'),
            FilledButton(
                onPressed: notifier.load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (notifier.result.items.isEmpty) {
      return const Center(child: Text('Авторы не найдены'));
    }

    final isCompact = MediaQuery.sizeOf(context).width < 600;

    if (isCompact) {
      return EntityCardList<Author>(
        items: notifier.result.items,
        idOf: (a) => a.id,
        selected: notifier.selected,
        onToggleSelect: notifier.toggleSelection,
        cardBuilder: (a) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(a.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            Text('Страна: ${a.country}', overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: (a) => [
          if (canEdit)
            Tooltip(
              message: 'Редактировать',
              child: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.go('/authors/${a.id}/edit')),
            ),
          Tooltip(
            message: 'Подробнее',
            child: IconButton(
                icon: const Icon(Icons.info),
                onPressed: () => context.go('/authors/${a.id}')),
          ),
        ],
      );
    }

    return EntityTable<Author>(
      items: notifier.result.items,
      idOf: (a) => a.id,
      selected: notifier.selected,
      onToggleSelect: notifier.toggleSelection,
      sortField: notifier.sortField,
      sortAscending: notifier.sortAscending,
      onSort: notifier.sortBy,
      columns: [
        TableColumnSpec(
            label: 'Фамилия',
            sortField: 'lastName',
            build: (a) => Text(a.lastName, overflow: TextOverflow.ellipsis)),
        TableColumnSpec(
            label: 'Имя',
            sortField: 'firstName',
            build: (a) => Text(a.firstName, overflow: TextOverflow.ellipsis)),
        TableColumnSpec(
            label: 'Страна',
            sortField: 'country',
            build: (a) => Text(a.country, overflow: TextOverflow.ellipsis)),
      ],
      actions: (a) => [
        if (canEdit)
          Tooltip(
            message: 'Редактировать',
            child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/authors/${a.id}/edit')),
          ),
        Tooltip(
          message: 'Подробнее',
          child: IconButton(
              icon: const Icon(Icons.info),
              onPressed: () => context.go('/authors/${a.id}')),
        ),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, AuthorListNotifier notifier) {
    if (notifier.result.items.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
                icon: const Icon(Icons.first_page),
                onPressed: notifier.result.page > 1
                    ? () => notifier.goToPage(1)
                    : null),
            IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: notifier.result.page > 1
                    ? () => notifier.goToPage(notifier.result.page - 1)
                    : null),
            Text('${notifier.result.page} / ${notifier.result.totalPages}'),
            IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: notifier.result.page < notifier.result.totalPages
                    ? () => notifier.goToPage(notifier.result.page + 1)
                    : null),
            IconButton(
                icon: const Icon(Icons.last_page),
                onPressed: notifier.result.page < notifier.result.totalPages
                    ? () => notifier.goToPage(notifier.result.totalPages)
                    : null),
            const SizedBox(width: 16),
            DropdownButton<int>(
              value: notifier.size,
              items: const [10, 25, 50]
                  .map((s) => DropdownMenuItem(value: s, child: Text('$s')))
                  .toList(),
              onChanged: (v) => notifier.setSize(v!),
            ),
          ],
        ),
      ),
    );
  }
}
