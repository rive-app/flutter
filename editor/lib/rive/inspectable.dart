import 'package:flutter/foundation.dart';

abstract class InspectorBase {
  String get name;
}

class InspectorGroup extends InspectorBase {
  @override
  String name;

  final bool canExpand;
  final bool canAdd;

  final List<InspectorItem> children;

  /// Listenable Expanded Notifier
  final isExpanded = ValueNotifier<bool>(false);

  void expand() {
    if (!canExpand) return;
    isExpanded.value = true;
  }

  void collapse() {
    if (!canExpand) return;
    isExpanded.value = false;
  }

  final Function() onAdd;

  InspectorGroup({
    @required this.name,
    @required this.children,
    this.canExpand = false,
    this.canAdd = false,
    this.onAdd,
  });
}

class InspectorItem extends InspectorBase {
  @override
  String name;

  final List<int> propertyKeys;

  InspectorItem({
    @required this.propertyKeys,
    @required this.name,
  });
}

