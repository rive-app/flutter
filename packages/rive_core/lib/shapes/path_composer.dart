import 'dart:ui' as ui;

import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/shapes/shape.dart';
import 'package:rive_core/src/generated/shapes/path_composer_base.dart';

class PathComposer extends PathComposerBase {
  Shape _shape;
  Shape get shape => _shape;

  // We currently only have one uiPath but this will change when we start
  // letting paths, strokes, fills, and the shape tell us what kind of uiPaths
  // they'll need. For now this is sufficient to get us going.
  final ui.Path uiPath = ui.Path();

  void _changeShape(Shape value) {
    // Clean up previous shape's path composer. This should never happen as we
    // don't let the user drag the path composer in the hierarchy, but may as
    // well be safe here in case some code moves it around
    if (_shape != null && _shape.pathComposer == this) {
      _shape.pathComposer = null;
    }

    // Let the new shape know we're its composer. I'm the composer now.
    // https://imgflip.com/i/3qjf6a
    value?.pathComposer = this;
    _shape = value;
  }

  void _recomputePath() {
    uiPath.reset();
    for (final path in _shape.paths) {
      uiPath.addPath(path.uiPath, ui.Offset.zero,
          matrix4: path.pathTransform?.mat4);
    }
    ui.Rect uiBounds = uiPath.getBounds();
    _shape.bounds = AABB.fromValues(
        uiBounds.left, uiBounds.top, uiBounds.right, uiBounds.bottom);
  }

  @override
  void buildDependencies() {
    super.buildDependencies();
    
    // We depend on the shape and all of its paths so that we can update after
    // all of them.
    if (_shape != null) {
      _shape.addDependent(this);
      for (final path in _shape?.paths) {
        path.addDependent(this);
      }
    }
  }

  @override
  void update(int dirt) {
    if (dirt & ComponentDirt.path != 0) {
      _recomputePath();
    }
  }

  @override
  void visitAncestor(Component ancestor) {
    if (ancestor is Shape) {
      _changeShape(ancestor);
    }
  }
}
