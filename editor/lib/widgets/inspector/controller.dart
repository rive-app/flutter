import 'package:flutter/material.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/selectable_item.dart';

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

class InspectorController extends ChangeNotifier {
  final _items = ValueNotifier<List<InspectorBase>>([]);
  ValueNotifier<List<InspectorBase>> get itemsListenable => _items;

  InspectorController();

  List<InspectorBase> get items => _items.value;
  set items(List<InspectorBase> values) => _items.value = values;

  void expandAll() {
    final _groups = _items.value.whereType<InspectorGroup>();
    for (final group in _groups) {
      group.expand();
    }
  }

  void collapseAll() {
    final _groups = _items.value.whereType<InspectorGroup>();
    for (final group in _groups) {
      group.collapse();
    }
  }

  bool get isEmpty => _items.value.isEmpty;

  void updateSelection(Set<SelectableItem> selecton) {
    items.clear();
    items.add(InspectorItem(name: 'Pos', propertyKeys: [
      ArtboardBase.xPropertyKey,
      ArtboardBase.yPropertyKey,
    ]));
    items.add(InspectorItem(name: 'Size', propertyKeys: [
      ArtboardBase.widthPropertyKey,
      ArtboardBase.heightPropertyKey,
    ]));
  }
}
