import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../core/validators.dart';
import '../state/genre_list_notifier.dart';
import '../models/genre.dart';

class GenreFormScreen extends StatefulWidget {
  final int? id;
  const GenreFormScreen({super.key, this.id});
  bool get isEditing => id != null;
  @override
  State<GenreFormScreen> createState() => _GenreFormScreenState();
}

class _GenreFormScreenState extends State<GenreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _hasChanges = false;
  bool _loadingData = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() {
      if (!_loadingData) {
        _hasChanges = true;
      }
    });
    _descController.addListener(() {
      if (!_loadingData) {
        _hasChanges = true;
      }
    });
    if (widget.isEditing) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    _loadingData = true;
    final notifier = context.read<GenreListNotifier>();
    final genre = await notifier.findById(widget.id!);
    if (genre != null && mounted) {
      setState(() {
        _nameController.text = genre.name;
        _descController.text = genre.description ?? '';
        _hasChanges = false;
      });
    }
    _loadingData = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final router = GoRouter.of(context);
    final notifier = context.read<GenreListNotifier>();
    final genre = Genre(
      id: widget.id ?? 0,
      name: _nameController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      deletedAt: null,
    );
    await notifier.save(genre);
    _hasChanges = false;
    router.go('/genres');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasChanges) {
          final navigator = Navigator.of(context);
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Несохранённые изменения'),
              content: const Text('Покинуть форму?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Отмена')),
                TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Покинуть')),
              ],
            ),
          );
          if (ok == true) {
            _hasChanges = false;
            if (mounted) {
              navigator.pop();
            }
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
            title:
                Text(widget.isEditing ? 'Редактировать жанр' : 'Новый жанр')),
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
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'Название', border: OutlineInputBorder()),
                    validator:
                        V.combine([V.required(), V.length(min: 2, max: 100)]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                        labelText: 'Описание', border: OutlineInputBorder()),
                    validator: V.length(max: 500),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submit,
                    child: Text(widget.isEditing ? 'Обновить' : 'Создать'),
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
