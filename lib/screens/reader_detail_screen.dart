import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/breakpoints.dart';
import '../models/reader.dart';
import '../state/reader_list_notifier.dart';

class ReaderDetailScreen extends StatefulWidget {
  final int id;
  const ReaderDetailScreen({super.key, required this.id});

  @override
  State<ReaderDetailScreen> createState() => _ReaderDetailScreenState();
}

class _ReaderDetailScreenState extends State<ReaderDetailScreen> {
  Reader? _reader;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await context.read<ReaderListNotifier>().findById(widget.id);
      if (!mounted) return;
      setState(() {
        _reader = r;
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
    final r = _reader;
    if (r == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Читатель')),
        body: const Center(child: Text('Читатель не найден')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(r.fullName, overflow: TextOverflow.ellipsis)),
      body: ContentConstraint(
        maxWidth: 720,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Фамилия: ${r.lastName}'),
                const SizedBox(height: 8),
                Text('Имя: ${r.firstName}'),
                const SizedBox(height: 8),
                if (r.middleName != null) ...[
                  Text('Отчество: ${r.middleName}'),
                  const SizedBox(height: 8),
                ],
                Text('Email: ${r.email}'),
                const Divider(height: 32, thickness: 1),
                const Text('Билет',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (r.card != null) ...[
                  Text('Штрихкод: ${r.card!.barcode}'),
                  const SizedBox(height: 8),
                  Text(
                      'Дата выдачи: ${r.card!.issuedAt.toLocal().toIso8601String().split('T').first}'),
                  const SizedBox(height: 8),
                  Text(
                      'Дата окончания: ${r.card!.expiresAt.toLocal().toIso8601String().split('T').first}'),
                  const SizedBox(height: 8),
                  Text('Статус: ${r.card!.isActive ? 'Активен' : 'Неактивен'}'),
                ] else
                  const Text('Билет не оформлен',
                      style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
