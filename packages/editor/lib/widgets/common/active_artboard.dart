// Artboard provider. This is responsible for propagating the active artboard
// down the widget tree. Handles things like switching current file, race
// conditions with backboard loading (which stores the activeArtboard), and
// finally activeArtboard changing on the backboard.

import 'package:flutter/material.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/backboard.dart';
// Weird, the package import fails here?
// import 'package:editor/rive/open_file_context.dart';
import '../../rive/open_file_context.dart';

class ActiveArtboard extends StatefulWidget {
  const ActiveArtboard({
    @required this.file,
    @required this.builder,
    this.child,
  });
  final Widget child;
  final OpenFileContext file;
  final Widget Function(BuildContext, Artboard, Widget) builder;

  @override
  _ActiveArtboardState createState() => _ActiveArtboardState();
}

class _ActiveArtboardState extends State<ActiveArtboard> {
  OpenFileContext _file;
  Backboard _backboard;
  Artboard _activeArtboard;
  void _setFile(OpenFileContext file) {
    _file?.stateChanged?.removeListener(_fileStateChanged);
    _file = file;
    _file?.stateChanged?.addListener(_fileStateChanged);
  }

  void _fileStateChanged() {
    // see if backboard is available
    var bb = _file.core.backboard;
    if (bb == _backboard) {
      return;
    }
    _backboard?.activeArtboardChanged?.removeListener(_artboardChanged);
    _backboard = bb;
    _backboard?.activeArtboardChanged?.addListener(_artboardChanged);
    _artboardChanged();
  }

  void _artboardChanged() {
    var ab = _backboard.activeArtboard;
    if (_activeArtboard == ab) {
      return;
    }
    setState(() {
      _activeArtboard = ab;
    });
  }

  @override
  void initState() {
    _setFile(widget.file);
    super.initState();
  }

  @override
  void didUpdateWidget(ActiveArtboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file != widget.file) {
      _setFile(widget.file);
    }
  }

  @override
  void dispose() {
    _file?.stateChanged?.removeListener(_fileStateChanged);
    _backboard?.activeArtboardChanged?.removeListener(_artboardChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(
        context,
        _activeArtboard,
        widget.child,
      );
}
