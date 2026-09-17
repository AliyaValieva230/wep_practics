import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/validators.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _userCtrl.dispose();
    _nameCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await context.read<AuthNotifier>().register(
            username: _userCtrl.text.trim(),
            fullName: _nameCtrl.text.trim(),
            password: _passCtrl.text,
          );
    } on ConflictException catch (e) {
      setState(() => _error = e.message);
    } on ValidationException catch (e) {
      setState(() => _error = e.errors.values.join(', '));
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _passwordHints(String p) {
    Widget row(bool ok, String label) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                ok ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: ok ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(color: ok ? Colors.green : Colors.grey)),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(p.length >= 8, 'Минимум 8 символов'),
        row(RegExp(r'\d').hasMatch(p), 'Хотя бы одна цифра'),
        row(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=~`\[\];/\\]').hasMatch(p),
            'Хотя бы один специальный символ'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final pass = _passCtrl.text;
    final strengthOk = pass.length >= 8 &&
        RegExp(r'\d').hasMatch(pass) &&
        RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-+=~`\[\];/\\]').hasMatch(pass);

    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _userCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Логин',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        V.combine([V.required(), V.length(min: 3, max: 50)]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Полное имя',
                      border: OutlineInputBorder(),
                    ),
                    validator:
                        V.combine([V.required(), V.length(min: 2, max: 100)]),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      border: OutlineInputBorder(),
                    ),
                    validator: V.strongPassword(),
                  ),
                  const SizedBox(height: 8),
                  _passwordHints(pass),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pass2Ctrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Повтор пароля',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v != _passCtrl.text ? 'Пароли не совпадают' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: (!strengthOk || _submitting) ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Зарегистрироваться'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('У меня уже есть аккаунт'),
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
