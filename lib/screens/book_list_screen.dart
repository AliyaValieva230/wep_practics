import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/role.dart';
import '../state/auth_notifier.dart';
import '../state/book_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/entity_table.dart';
import '../widgets/entity_card_list.dart';
import '../models/book.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});
  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  int _selectedIndex = 0;

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
      child: Consumer<BookListNotifier>(
        builder: (context, notifier, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Книги'),
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
                    onPressed: () => context.go('/books/new'),
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Поиск по названию или ISBN',
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
      BuildContext context, BookListNotifier notifier, bool canEdit) {
    if (notifier.status == LoadStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (notifier.status == LoadStatus.error) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ошибка: ${notifier.error}'),
            const SizedBox(height: 8),
            FilledButton(
                onPressed: notifier.load, child: const Text('Повторить')),
          ],
        ),
      );
    }
    if (notifier.result.items.isEmpty) {
      return const Center(child: Text('Книг не найдено'));
    }

    final isCompact = MediaQuery.sizeOf(context).width < 600;

    if (isCompact) {
      return EntityCardList<Book>(
        items: notifier.result.items,
        idOf: (b) => b.id,
        selected: notifier.selected,
        onToggleSelect: notifier.toggleSelection,
        cardBuilder: (book) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(book.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
                maxLines: 2),
            Text('Год: ${book.year}, Страниц: ${book.pages}'),
            Text('ISBN: ${book.isbn}', overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: (book) => [
          if (canEdit)
            Tooltip(
              message: 'Редактировать',
              child: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => context.go('/books/${book.id}/edit'),
              ),
            ),
          Tooltip(
            message: 'Подробнее',
            child: IconButton(
              icon: const Icon(Icons.info),
              onPressed: () => context.go('/books/${book.id}'),
            ),
          ),
        ],
      );
    }

    return EntityTable<Book>(
      items: notifier.result.items,
      idOf: (b) => b.id,
      selected: notifier.selected,
      onToggleSelect: notifier.toggleSelection,
      sortField: notifier.sortField,
      sortAscending: notifier.sortAscending,
      onSort: notifier.sortBy,
      columns: [
        TableColumnSpec(
            label: 'Название',
            sortField: 'title',
            build: (b) => ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(b.title, overflow: TextOverflow.ellipsis),
                )),
        TableColumnSpec(
            label: 'Год',
            sortField: 'year',
            numeric: true,
            build: (b) => Text('${b.year}')),
        TableColumnSpec(
            label: 'Страниц',
            sortField: 'pages',
            numeric: true,
            build: (b) => Text('${b.pages}')),
        TableColumnSpec(
            label: 'ISBN',
            build: (b) => Text(b.isbn, overflow: TextOverflow.ellipsis)),
      ],
      actions: (book) => [
        if (canEdit)
          Tooltip(
            message: 'Редактировать',
            child: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.go('/books/${book.id}/edit'),
            ),
          ),
        Tooltip(
          message: 'Подробнее',
          child: IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => context.go('/books/${book.id}'),
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(BuildContext context, BookListNotifier notifier) {
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
            const SizedBox(width: 16),
            Text('Всего: ${notifier.result.total}'),
          ],
        ),
      ),
    );
  }
}
