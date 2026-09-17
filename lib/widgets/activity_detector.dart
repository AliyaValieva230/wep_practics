import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ActivityDetector extends StatefulWidget {
  final VoidCallback onActivity;
  final Widget child;
  const ActivityDetector({
    super.key,
    required this.onActivity,
    required this.child,
  });

  @override
  State<ActivityDetector> createState() => _ActivityDetectorState();
}

class _ActivityDetectorState extends State<ActivityDetector> {
  bool _onKey(KeyEvent _) {
    widget.onActivity();
    return false;
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => widget.onActivity(),
      onPointerMove: (_) => widget.onActivity(),
      onPointerSignal: (_) => widget.onActivity(),
      child: widget.child,
    );
  }
}
