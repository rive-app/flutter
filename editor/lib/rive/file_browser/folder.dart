import 'package:flutter/material.dart';

import 'file.dart';

class FolderItem extends ChangeNotifier {
  final String name;
  final Key key;
  final List<FileItem> files;

  FolderItem({
    @required this.key,
    @required this.name,
    this.files = const [],
  });

  bool _selected = false;
  bool get selected => _selected;
  void onSelect(bool value) {
    _selected = value;
    notifyListeners();
  }
}
