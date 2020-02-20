import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/inspectable.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class InspectorController extends ChangeNotifier {
  final _items = ValueNotifier<Set<InspectorBase>>({});
  ValueNotifier<Set<InspectorBase>> get itemsListenable => _items;

  InspectorController();

  Set<InspectorBase> get items => _items.value;
  set items(Set<InspectorBase> values) => _items.value = values;

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

  void updateSelection(Set<SelectableItem> selection) {
    items.clear();
    if (selection.isEmpty) return;
    for (final item in selection.whereType<StageItem>()) {
      items.addAll(item.inspectorItems);
    }
  }
}
