import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';

import 'file.dart';

class FolderItem extends SelectableItem {
  final String name;
  final ValueKey<String> key;
  final List<FileItem> files;
  final List<FolderItem> folders;

  FolderItem({
    @required this.key,
    @required this.name,
    this.files = const [],
    this.folders = const [],
  });
  final _draggingState = ValueNotifier<bool>(false);
  ValueListenable<bool> get draggingState => _draggingState;
  set isDragging(bool val) => _draggingState.value = val;
  bool get isDragging => _draggingState.value;

  bool get hasFiles => files != null && files.isNotEmpty;
  bool get hasFolders => folders != null && folders.isNotEmpty;
}
