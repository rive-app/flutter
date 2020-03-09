import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/folder.dart';
import 'package:rive_core/selectable_item.dart';

import 'rive_file.dart';

/// Represents a folder in the Rive cloud, owned by a user or a team.
class RiveFolder extends RiveApiFolder with SelectableItem {
  ValueKey<String> _key;
  final _draggingState = ValueNotifier<bool>(false);
  final files = ValueNotifier<List<RiveFile>>([]);

  RiveFolder(Map<String, dynamic> data) : super(data) {
    _key = ValueKey<String>(id);
  }
  ValueListenable<bool> get draggingState => _draggingState;
  bool get hasFolders => children?.isNotEmpty ?? false;
  bool get isDragging => _draggingState.value;

  // bool get hasFiles => files != null && files.isNotEmpty;
  set isDragging(bool val) => _draggingState.value = val;

  ValueKey<String> get key => _key;
}
