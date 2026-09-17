import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';

class SessionWarningBanner extends StatelessWidget {
  const SessionWarningBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthNotifier>(
      builder: (context, auth, _) {
        if (!auth.warningActive) return const SizedBox.shrink();
        final s = auth.warningSecondsLeft;
        return MaterialBanner(
          backgroundColor: Colors.orange.shade100,
          leading: const Icon(Icons.timer_outlined),
          content: Text('Сессия истечёт через $s с. Продолжите работу.'),
          actions: [
            TextButton(
              onPressed: () => auth.noteActivity(),
              child: const Text('Продолжить'),
            ),
            TextButton(
              onPressed: () => auth.logout(reason: 'Выход по требованию'),
              child: const Text('Выйти'),
            ),
          ],
        );
      },
    );
  }
}
