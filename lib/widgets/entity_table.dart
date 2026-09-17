import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints:
              BoxConstraints(minWidth: MediaQuery.sizeOf(context).width),
          child: DataTable(
            sortColumnIndex: _sortIndex(),
            sortAscending: sortAscending,
            columns: [
              const DataColumn(label: SizedBox(width: 48, child: Text(''))),
              ...columns.map((c) => DataColumn(
                    label: Text(c.label),
                    numeric: c.numeric,
                    onSort: c.sortField != null && onSort != null
                        ? (_, __) => onSort!(c.sortField!)
                        : null,
                  )),
              if (actions != null) const DataColumn(label: Text('Действия')),
            ],
            rows: items.map((item) {
              final id = idOf(item);
              return DataRow(
                selected: selected.contains(id),
                cells: [
                  DataCell(Checkbox(
                    value: selected.contains(id),
                    onChanged: onToggleSelect != null
                        ? (_) => onToggleSelect!(id)
                        : null,
                  )),
                  ...columns.map((c) => DataCell(c.build(item))),
                  if (actions != null)
                    DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: actions!(item))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  int? _sortIndex() {
    if (sortField == null) return null;
    for (var i = 0; i < columns.length; i++) {
      if (columns[i].sortField == sortField) return i + 1;
    }
    return null;
  }
}
