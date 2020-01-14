import 'package:flutter/material.dart';

class FileItem extends ChangeNotifier {
  final String name;
  final String image;
  final Key key;

  FileItem({
    @required this.key,
    @required this.name,
    @required this.image,
  });

  bool _selected = false;
  bool get selected => _selected;
  void onSelect(bool value) {
    _selected = value;
    notifyListeners();
  }
}
