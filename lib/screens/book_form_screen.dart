import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../core/validators.dart';
import '../core/api_exceptions.dart';
import '../state/book_list_notifier.dart';
import '../state/author_list_notifier.dart';
import '../state/genre_list_notifier.dart';
import '../state/publisher_list_notifier.dart';
import '../models/book.dart';

class BookFormScreen extends StatefulWidget {
  final int? id;
  const BookFormScreen({super.key, this.id});
  bool get isEditing => id != null;
  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController();
  final _pagesController = TextEditingController();
  final _copiesTotalController = TextEditingController();
  final _copiesAvailableController = TextEditingController();
  int? _publisherId;
  List<int> _authorIds = [];
  List<int> _genreIds = [];
  Map<String, String> _serverErrors = {};
  bool _hasChanges = false;
  bool _saving = false;
  bool _loadingData = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _titleController,
      _isbnController,
      _yearController,
      _pagesController,
      _copiesTotalController,
      _copiesAvailableController,
    ]) {
      c.addListener(() {
        if (!_loadingData) {
          _hasChanges = true;
        }
      });
    }
    if (widget.isEditing) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    _loadingData = true;
    final notifier = context.read<BookListNotifier>();
    final book = await notifier.findById(widget.id!);
    if (book != null && mounted) {
      setState(() {
        _titleController.text = book.title;
        _isbnController.text = book.isbn;
        _yearController.text = book.year.toString();
        _pagesController.text = book.pages.toString();
        _copiesTotalController.text = book.copiesTotal.toString();
        _copiesAvailableController.text = book.copiesAvailable.toString();
        _publisherId = book.publisherId;
        _authorIds = List.from(book.authorIds);
        _genreIds = List.from(book.genreIds);
        _hasChanges = false;
      });
    }
    _loadingData = false;
  }

  @override
  void dispose() {
    for (final c in [
      _titleController,
      _isbnController,
      _yearController,
      _pagesController,
      _copiesTotalController,
      _copiesAvailableController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<bool> _showDiscardDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Покинуть форму без сохранения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Покинуть'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  Widget _buildMultiSelect<T>({
    required String label,
    required List<T> items,
    required List<int> selectedIds,
    required ValueChanged<List<int>> onChanged,
    required int Function(T) idGetter,
    required String Function(T) labelGetter,
  }) {
    return FormField<List<int>>(
      key: ValueKey('$label-${selectedIds.join(",")}'),
      initialValue: selectedIds,
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Выберите хотя бы один' : null,
      builder: (field) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            errorText: field.errorText,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final id = idGetter(item);
              final selected = (field.value ?? const <int>[]).contains(id);
              return FilterChip(
                label: Text(
                  labelGetter(item),
                  overflow: TextOverflow.ellipsis,
                ),
                selected: selected,
                onSelected: (_) {
                  final next = List<int>.from(field.value ?? const <int>[]);
                  if (selected) {
                    next.remove(id);
                  } else {
                    next.add(id);
                  }
                  field.didChange(next);
                  onChanged(next);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Book _buildBook() => Book(
        id: widget.id ?? 0,
        title: _titleController.text.trim(),
        isbn: _isbnController.text.trim(),
        year: int.parse(_yearController.text),
        pages: int.parse(_pagesController.text),
        publisherId: _publisherId!,
        authorIds: _authorIds,
        genreIds: _genreIds,
        copiesTotal: int.parse(_copiesTotalController.text),
        copiesAvailable: int.parse(_copiesAvailableController.text),
        deletedAt: null,
      );

  Future<void> _submit() async {
    setState(() {
      _serverErrors = {};
    });
    if (!_formKey.currentState!.validate()) return;

    final total = int.tryParse(_copiesTotalController.text);
    final avail = int.tryParse(_copiesAvailableController.text);
    if (total != null && avail != null && avail > total) {
      setState(
          () => _serverErrors['copiesAvailable'] = 'Больше общего количества');
      _formKey.currentState!.validate();
      return;
    }

    setState(() => _saving = true);
    final router = GoRouter.of(context);
    final notifier = context.read<BookListNotifier>();
    try {
      await notifier.save(_buildBook());
      _hasChanges = false;
      router.go('/books');
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate();
    } on ConflictException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.orange),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authors = context.watch<AuthorListNotifier>().result.items;
    final genres = context.watch<GenreListNotifier>().result.items;
    final publishers = context.watch<PublisherListNotifier>().result.items;

    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          final navigator = Navigator.of(context);
          final ok = await _showDiscardDialog();
          if (ok) {
            _hasChanges = false;
            if (mounted) {
              navigator.pop();
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'Редактировать книгу' : 'Новая книга'),
        ),
        body: ContentConstraint(
          maxWidth: 720,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Название',
                      border: const OutlineInputBorder(),
                      errorText: _serverErrors['title'],
                    ),
                    validator:
                        V.combine([V.required(), V.length(min: 2, max: 255)]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _isbnController,
                    decoration: InputDecoration(
                      labelText: 'ISBN',
                      border: const OutlineInputBorder(),
                      errorText: _serverErrors['isbn'],
                    ),
                    validator: V.combine([V.required(), V.isbn()]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _yearController,
                    decoration: InputDecoration(
                      labelText: 'Год',
                      border: const OutlineInputBorder(),
                      errorText: _serverErrors['year'],
                    ),
                    keyboardType: TextInputType.number,
                    validator: V.combine(
                        [V.required(), V.integer(min: 1450, max: 2100)]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pagesController,
                    decoration: InputDecoration(
                      labelText: 'Страниц',
                      border: const OutlineInputBorder(),
                      errorText: _serverErrors['pages'],
                    ),
                    keyboardType: TextInputType.number,
                    validator: V.combine([V.required(), V.positiveInt()]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _copiesTotalController,
                    decoration: InputDecoration(
                      labelText: 'Всего экз.',
                      border: const OutlineInputBorder(),
                      errorText: _serverErrors['copiesTotal'],
                    ),
                    keyboardType: TextInputType.number,
                    validator: V.combine([V.required(), V.positiveInt()]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _copiesAvailableController,
                    decoration: InputDecoration(
                      labelText: 'Доступно экз.',
                      border: const OutlineInputBorder(),
                      errorText: _serverErrors['copiesAvailable'],
                    ),
                    keyboardType: TextInputType.number,
                    validator: V.combine([V.required(), V.integer(min: 0)]),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    key: ValueKey('publisher-$_publisherId'),
                    value: _publisherId,
                    decoration: InputDecoration(
                      labelText: 'Издательство',
                      border: const OutlineInputBorder(),
                      errorText: _serverErrors['publisherId'],
                    ),
                    items: publishers
                        .map((p) => DropdownMenuItem(
                              value: p.id,
                              child:
                                  Text(p.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _publisherId = v),
                    validator: (v) =>
                        v == null ? 'Выберите издательство' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildMultiSelect(
                    label: 'Авторы',
                    items: authors,
                    selectedIds: _authorIds,
                    onChanged: (v) => setState(() => _authorIds = v),
                    idGetter: (a) => a.id,
                    labelGetter: (a) => a.fullName,
                  ),
                  const SizedBox(height: 12),
                  _buildMultiSelect(
                    label: 'Жанры',
                    items: genres,
                    selectedIds: _genreIds,
                    onChanged: (v) => setState(() => _genreIds = v),
                    idGetter: (g) => g.id,
                    labelGetter: (g) => g.name,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.isEditing ? 'Обновить' : 'Создать'),
                  ),
                  if (_serverErrors.containsKey('general'))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _serverErrors['general']!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
