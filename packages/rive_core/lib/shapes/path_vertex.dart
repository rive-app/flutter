import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/src/generated/shapes/path_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/path_vertex_base.dart';

abstract class PathVertex extends PathVertexBase {
  Path get path => parent as Path;
  // -> editor-only
  BoundsDelegate _delegate;
  @override
  String get timelineParentGroup => 'vertices';
  @override
  Component get timelineParent => parent;

  @override
  String get timelineName => 'Vertex ${path.vertices.indexOf(this) + 1}';
  @override
  bool get canRename => false;
  // <- editor-only

  // -> editor-only
  // At edit time we want to have a reference to the original
  // vertex that may have created this vertex. If original is null and context
  // is not null, this is a core vertex (original).
  bool isCornerRadius = false;
  PathVertex original;
  PathVertex get coreVertex {
    if (original != null) {
      return original.coreVertex;
    }
    assert(context != null,
        'the original vertex should never have a null context');
    return this;
  }
  // <- editor-only

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
  // <- editor-only

  @override
  void update(int dirt) {
    // -> editor-only
    if (dirt & ComponentDirt.worldTransform != 0) {
      _delegate?.boundsChanged();
    }
    // <- editor-only
  }

  // -> editor-only
  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is BoundsDelegate) {
      _delegate = to;
    } else {
      _delegate = null;
    }
  }
  // <- editor-only

  Vec2D get translation {
    return Vec2D.fromValues(x, y);
  }

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

  // -> editor-only

  /// Returns the vertex that will immediately follow this one after
  /// replacement.
  PathVertex replaceWith(PathVertex newVertex) {
    // We need to replace the entire vertex with one of a different
    // type. This is messy because we also need it to maintain the
    // same order/index in the list.
    var index = path.vertices.indexOf(this);
    var next = path.vertices[(index + 1) % path.vertices.length];
    remove();
    newVertex.x = x;
    newVertex.y = y;
    newVertex.childOrder = childOrder;
    context.addObject(newVertex);
    newVertex.parent = path;
    return next;
  }

  void clearWeight() {
    weightIndices = weights = 0;
  }

  void initWeight() {
    weightIndices = 1;
    weights = 255;
  }
  // <- editor-only

  @override
  void weightIndicesChanged(int from, int to) {}

  @override
  void weightsChanged(int from, int to) {}
}
