import 'package:flutter/widgets.dart';

enum ScreenSize { compact, medium, expanded }

ScreenSize screenSizeOf(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w < 600) return ScreenSize.compact;
  if (w < 1200) return ScreenSize.medium;
  return ScreenSize.expanded;
}

T byScreen<T>(
  BuildContext context, {
  required T compact,
  T? medium,
  T? expanded,
}) {
  return switch (screenSizeOf(context)) {
    ScreenSize.compact => compact,
    ScreenSize.medium => medium ?? compact,
    ScreenSize.expanded => expanded ?? medium ?? compact,
  };
}

class ContentConstraint extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ContentConstraint({
    super.key,
    required this.child,
    this.maxWidth = 960,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
