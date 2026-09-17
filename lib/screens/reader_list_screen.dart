import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/role.dart';
import '../state/auth_notifier.dart';
import '../state/reader_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/entity_table.dart';
import '../widgets/entity_card_list.dart';
import '../models/reader.dart';

class ReaderListScreen extends StatefulWidget {
  const ReaderListScreen({super.key});
  @override
  State<ReaderListScreen> createState() => _ReaderListScreenState();
}

class _ReaderListScreenState extends State<ReaderListScreen> {
  int _selectedIndex = 4;

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
      child: Consumer<ReaderListNotifier>(
        builder: (context, notifier, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Читатели'),
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
                      onPressed: () => context.go('/readers/new')),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Поиск по ФИО или email',
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
      BuildContext context, ReaderListNotifier notifier, bool canEdit) {
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
      return const Center(child: Text('Читатели не найдены'));
    }

    final isCompact = MediaQuery.sizeOf(context).width < 600;

    if (isCompact) {
      return EntityCardList<Reader>(
        items: notifier.result.items,
        idOf: (r) => r.id,
        selected: notifier.selected,
        onToggleSelect: notifier.toggleSelection,
        cardBuilder: (r) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis),
            Text('Email: ${r.email}', overflow: TextOverflow.ellipsis),
            Text('Билет: ${r.card != null ? r.card!.barcode : 'нет'}',
                overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: (r) => [
          if (canEdit)
            Tooltip(
              message: 'Редактировать',
              child: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => context.go('/readers/${r.id}/edit')),
            ),
          Tooltip(
            message: 'Подробнее',
            child: IconButton(
                icon: const Icon(Icons.info),
                onPressed: () => context.go('/readers/${r.id}')),
          ),
        ],
      );
    }

    return EntityTable<Reader>(
      items: notifier.result.items,
      idOf: (r) => r.id,
      selected: notifier.selected,
      onToggleSelect: notifier.toggleSelection,
      sortField: notifier.sortField,
      sortAscending: notifier.sortAscending,
      onSort: notifier.sortBy,
      columns: [
        TableColumnSpec(
            label: 'Фамилия',
            sortField: 'lastName',
            build: (r) => Text(r.lastName, overflow: TextOverflow.ellipsis)),
        TableColumnSpec(
            label: 'Имя',
            sortField: 'firstName',
            build: (r) => Text(r.firstName, overflow: TextOverflow.ellipsis)),
        TableColumnSpec(
            label: 'Email',
            sortField: 'email',
            build: (r) => Text(r.email, overflow: TextOverflow.ellipsis)),
        TableColumnSpec(
            label: 'Билет',
            build: (r) => Text(r.card != null ? r.card!.barcode : '-',
                overflow: TextOverflow.ellipsis)),
      ],
      actions: (r) => [
        if (canEdit)
          Tooltip(
            message: 'Редактировать',
            child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/readers/${r.id}/edit')),
          ),
        Tooltip(
          message: 'Подробнее',
          child: IconButton(
              icon: const Icon(Icons.info),
              onPressed: () => context.go('/readers/${r.id}')),
        ),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, ReaderListNotifier notifier) {
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
