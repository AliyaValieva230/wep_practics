import 'package:flutter/material.dart';

class EntityCardList<T> extends StatelessWidget {
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final Widget Function(T item) cardBuilder;
  final List<Widget> Function(T item)? actions;

  const EntityCardList({
    super.key,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    required this.cardBuilder,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = items[index];
        final id = idOf(item);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onToggleSelect != null)
                  Checkbox(
                      value: selected.contains(id),
                      onChanged: (_) => onToggleSelect!(id)),
                Expanded(child: cardBuilder(item)),
                if (actions != null)
                  Row(mainAxisSize: MainAxisSize.min, children: actions!(item)),
              ],
            ),
          ),
        );
      },
    );
  }
}
