import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/change_notifier.dart';
import 'package:rive_core/selectable_item.dart';

class FileItem extends SelectableItem {
  final String name;
  final String image;
  final Key key;

  FileItem({
    @required this.key,
    @required this.name,
    @required this.image,
  });

  final _state = ValueNotifier<SelectionState>(SelectionState.none);

  @override
  void select(SelectionState state) => _state.value = state;

  @override
  ValueListenable<SelectionState> get selectionState => _state;
}
