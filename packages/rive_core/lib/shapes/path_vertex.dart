import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/src/generated/shapes/path_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/path_vertex_base.dart';

abstract class PathVertex extends PathVertexBase {
  Path get path => parent as Path;
  BoundsDelegate _delegate;

  // -> editor-only
  // At runtime we don't want the vertices to depend on anything
  // as there can be a lot of them and they should be really lightweight,
  // calling directly up to the parent if a change occurs that requires a
  // rebuild of the path. The editor needs a little more data in order to draw
  // the stage handles for the vertices at the right point and be notified
  // whenever a transform of one of those points changes.
  @override
  void buildDependencies() {
    super.buildDependencies();
    parent?.addDependent(this);
  }

  @override
  void update(int dirt) {
    if (dirt & ComponentDirt.worldTransform != 0) {
      _delegate?.boundsChanged();
    }
  }

  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is BoundsDelegate) {
      _delegate = to;
    } else {
      _delegate = null;
    }
  }
  // <- editor-only

  Vec2D get translation => Vec2D.fromValues(x, y);
  set translation(Vec2D value) {
    x = value[0];
    y = value[1];
  }

  @override
  void xChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
    path?.markPathDirty();
  }

  @override
  void yChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
    path?.markPathDirty();
  }

  @override
  String toString() {
    return translation.toString();
  }
}
