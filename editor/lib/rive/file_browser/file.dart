import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';

class FileItem extends SelectableItem {
  final String name;
  final String image;
  final ValueKey<String> key;

  FileItem({
    @required this.key,
    @required this.name,
    @required this.image,
  });
  final _draggingState = ValueNotifier<bool>(false);
  ValueListenable<bool> get draggingState => _draggingState;
  set isDragging(bool val) => _draggingState.value = val;
  bool get isDragging => _draggingState.value;
}
