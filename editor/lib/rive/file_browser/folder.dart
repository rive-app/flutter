import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';

import 'file.dart';

class FolderItem extends SelectableItem {
  final String name;
  final Key key;
  final List<FileItem> files;

  FolderItem({
    @required this.key,
    @required this.name,
    this.files = const [],
  });

  final _state = ValueNotifier<SelectionState>(SelectionState.none);

  @override
  void select(SelectionState state) => _state.value = state;

  @override
  ValueListenable<SelectionState> get selectionState => _state;
}
