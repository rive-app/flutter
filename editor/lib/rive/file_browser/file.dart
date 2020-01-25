import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/cdn.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_api/file.dart';

import 'file_browser.dart';

class RiveFile extends RiveApiFile with SelectableItem, ChangeNotifier {
  final ValueKey<String> key;
  final FileBrowser browser;
  bool _loaded = false;

  RiveFile(String id, this.browser)
      : key = ValueKey<String>(id),
        super(id);

  void allowReloadDetails() {
    _loaded = false;
  }

  final _draggingState = ValueNotifier<bool>(false);
  ValueListenable<bool> get draggingState => _draggingState;
  set isDragging(bool val) => _draggingState.value = val;
  bool get isDragging => _draggingState.value;

  void needDetails() {
    if (!_loaded) {
      browser.queueLoadDetails(this);
    }
  }

  void doneWithDetails() {
    browser.dequeueLoadDetails(this);
  }

  @override
  bool deserialize(RiveCDN cdn, Map<String, dynamic> data) {
    _loaded = true;
    if (super.deserialize(cdn, data)) {
      // notify if deserialize changes some value...
      notifyListeners();
      return true;
    }
    return false;
  }
}

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
