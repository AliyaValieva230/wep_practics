import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../models/book.dart';
import '../state/book_list_notifier.dart';

class BookDetailScreen extends StatefulWidget {
  final int id;
  const BookDetailScreen({super.key, required this.id});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  Book? _book;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final b = await context.read<BookListNotifier>().findById(widget.id);
      if (!mounted) return;
      setState(() {
        _book = b;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final book = _book;
    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Книга')),
        body: const Center(child: Text('Книга не найдена')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(book.title, overflow: TextOverflow.ellipsis)),
      body: ContentConstraint(
        maxWidth: 720,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ISBN: ${book.isbn}'),
                const SizedBox(height: 8),
                Text('Год: ${book.year}'),
                const SizedBox(height: 8),
                Text('Страниц: ${book.pages}'),
                const SizedBox(height: 8),
                Text('Издательство ID: ${book.publisherId}'),
                const SizedBox(height: 8),
                Text('Авторы: ${book.authorIds}'),
                const SizedBox(height: 8),
                Text('Жанры: ${book.genreIds}'),
                const SizedBox(height: 8),
                Text(
                    'Всего: ${book.copiesTotal}, Доступно: ${book.copiesAvailable}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
