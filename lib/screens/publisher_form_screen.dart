import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../core/validators.dart';
import '../state/publisher_list_notifier.dart';
import '../models/publisher.dart';

class PublisherFormScreen extends StatefulWidget {
  final int? id;
  const PublisherFormScreen({super.key, this.id});
  bool get isEditing => id != null;
  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
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
    _addressController.addListener(() {
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
    final notifier = context.read<PublisherListNotifier>();
    final p = await notifier.findById(widget.id!);
    if (p != null && mounted) {
      setState(() {
        _nameController.text = p.name;
        _addressController.text = p.address ?? '';
        _hasChanges = false;
      });
    }
    _loadingData = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final router = GoRouter.of(context);
    final notifier = context.read<PublisherListNotifier>();
    final publisher = Publisher(
      id: widget.id ?? 0,
      name: _nameController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      deletedAt: null,
    );
    await notifier.save(publisher);
    _hasChanges = false;
    router.go('/publishers');
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
            title: Text(widget.isEditing
                ? 'Редактировать издательство'
                : 'Новое издательство')),
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
                        V.combine([V.required(), V.length(min: 2, max: 200)]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                        labelText: 'Адрес', border: OutlineInputBorder()),
                    validator: V.length(max: 300),
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
