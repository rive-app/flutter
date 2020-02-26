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

  /// Allow editing the List<InspectorProperty> together in a single operation
  final bool linkable;

  final List<InspectorProperty> properties;

  InspectorItem({
    @required this.properties,
    @required this.name,
    this.linkable = false,
  });
}

class InspectorProperty {
  final int key;
  final String label;

  InspectorProperty({
    @required this.key,
    this.label,
  });
}
