import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../core/validators.dart';
import '../state/reader_list_notifier.dart';
import '../models/reader.dart';
import '../models/library_card.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? id;
  const ReaderFormScreen({super.key, this.id});
  bool get isEditing => id != null;
  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _issuedAtController = TextEditingController();
  final _expiresAtController = TextEditingController();
  bool _isActive = true;
  int? _cardId;
  Map<String, String> _serverErrors = {};
  bool _hasChanges = false;
  bool _loadingData = false;

  @override
  void initState() {
    super.initState();
    for (final c in [
      _firstNameController,
      _lastNameController,
      _middleNameController,
      _emailController,
      _barcodeController,
      _issuedAtController,
      _expiresAtController,
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
    final notifier = context.read<ReaderListNotifier>();
    final r = await notifier.findById(widget.id!);
    if (r != null && mounted) {
      setState(() {
        _firstNameController.text = r.firstName;
        _lastNameController.text = r.lastName;
        _middleNameController.text = r.middleName ?? '';
        _emailController.text = r.email;
        if (r.card != null) {
          _cardId = r.card!.id;
          _barcodeController.text = r.card!.barcode;
          _issuedAtController.text =
              r.card!.issuedAt.toLocal().toString().split(' ')[0];
          _expiresAtController.text =
              r.card!.expiresAt.toLocal().toString().split(' ')[0];
          _isActive = r.card!.isActive;
        }
        _hasChanges = false;
      });
    }
    _loadingData = false;
  }

  @override
  void dispose() {
    for (final c in [
      _firstNameController,
      _lastNameController,
      _middleNameController,
      _emailController,
      _barcodeController,
      _issuedAtController,
      _expiresAtController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Validator _dateValidator() {
    return (v) {
      final t = v?.trim() ?? '';
      if (t.isEmpty) {
        return 'Поле обязательно';
      }
      if (DateTime.tryParse(t) == null) {
        return 'Формат: ГГГГ-ММ-ДД';
      }
      return null;
    };
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate()) return;

    final issued = DateTime.parse(_issuedAtController.text.trim());
    final expires = DateTime.parse(_expiresAtController.text.trim());
    if (!expires.isAfter(issued)) {
      setState(() => _serverErrors['expiresAt'] =
          'Дата окончания должна быть позже выдачи');
      _formKey.currentState!.validate();
      return;
    }

    final router = GoRouter.of(context);
    final notifier = context.read<ReaderListNotifier>();
    final card = LibraryCard(
      id: _cardId ?? 0,
      readerId: widget.id ?? 0,
      barcode: _barcodeController.text.trim(),
      issuedAt: issued,
      expiresAt: expires,
      isActive: _isActive,
    );
    final reader = Reader(
      id: widget.id ?? 0,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      middleName: _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      email: _emailController.text.trim(),
      card: card,
      deletedAt: null,
    );
    await notifier.save(reader);
    _hasChanges = false;
    router.go('/readers');
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
                ? 'Редактировать читателя'
                : 'Новый читатель')),
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
                    controller: _lastNameController,
                    decoration: const InputDecoration(
                        labelText: 'Фамилия', border: OutlineInputBorder()),
                    validator:
                        V.combine([V.required(), V.length(min: 2, max: 100)]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(
                        labelText: 'Имя', border: OutlineInputBorder()),
                    validator:
                        V.combine([V.required(), V.length(min: 2, max: 100)]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _middleNameController,
                    decoration: const InputDecoration(
                        labelText: 'Отчество', border: OutlineInputBorder()),
                    validator: V.length(max: 100),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                        labelText: 'Email',
                        border: const OutlineInputBorder(),
                        errorText: _serverErrors['email']),
                    validator: V.combine([V.required(), V.email()]),
                  ),
                  const Divider(height: 32, thickness: 1),
                  const Text('Билет',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                        labelText: 'Штрихкод', border: OutlineInputBorder()),
                    validator:
                        V.combine([V.required(), V.length(min: 8, max: 20)]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _issuedAtController,
                    decoration: const InputDecoration(
                        labelText: 'Дата выдачи (ГГГГ-ММ-ДД)',
                        border: OutlineInputBorder()),
                    validator: _dateValidator(),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _expiresAtController,
                    decoration: InputDecoration(
                        labelText: 'Дата окончания (ГГГГ-ММ-ДД)',
                        border: const OutlineInputBorder(),
                        errorText: _serverErrors['expiresAt']),
                    validator: _dateValidator(),
                  ),
                  SwitchListTile(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    title: const Text('Активен'),
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
