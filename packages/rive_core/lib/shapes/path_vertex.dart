import 'dart:typed_data';

import 'package:core/core.dart';
import 'package:rive_core/bones/weight.dart';
import 'package:rive_core/bones/weighted_vertex.dart';
import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/src/generated/shapes/path_vertex_base.dart';
export 'package:rive_core/src/generated/shapes/path_vertex_base.dart';

abstract class PathVertex<T extends Weight> extends PathVertexBase {
  T _weight;
  T get weight => _weight;

  Path get path => parent is Path ? parent as Path : null;
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

  final Vec2D _renderTranslation = Vec2D();
  Vec2D get translation => Vec2D.fromValues(x, y);
  Vec2D get renderTranslation => _renderTranslation;

  set translation(Vec2D value) {
    x = value[0];
    y = value[1];
  }

  @override
  void xChanged(double from, double to) {
    _renderTranslation[0] = to;
    // -> editor-only
    addDirt(ComponentDirt.worldTransform);
    // <- editor-only
    path?.markPathDirty();
  }

  @override
  void yChanged(double from, double to) {
    _renderTranslation[1] = to;
    // -> editor-only
    addDirt(ComponentDirt.worldTransform);
    // <- editor-only
    path?.markPathDirty();
  }

  @override
  String toString() {
    return translation.toString();
  }

  @override
  void childAdded(Component component) {
    super.childAdded(component);
    if (component is T) {
      _weight = component;
    }
  }

  @override
  void childRemoved(Component component) {
    super.childRemoved(component);
    if (_weight == component) {
      _weight = null;
    }
  }

  void deform(Mat2D world, Float32List boneTransforms) {
    Weight.deform(x, y, weight.indices, weight.values, world, boneTransforms,
        _weight.translation);
  }
  // -> editor-only

  @override
  void childOrderChanged(FractionalIndex from, FractionalIndex to) {
    super.childOrderChanged(from, to);

    // Let the path know it needs to update and re-sort vertices.
    path?.markPathDirty();
    path?.addDirt(ComponentDirt.vertices);
  }

  void cloneWeight(Weight weight);

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

    if (weight != null) {
      newVertex.cloneWeight(weight);
    }

    return next;
  }

  void initWeight();

  bool validateWeight(int tendonCount) {
    if (weight == null) {
      initWeight();
      return false;
    }
    var helpers = weightedVertices;
    bool wasValid = true;
    for (final helper in helpers) {
      for (int i = 0; i < 4; i++) {
        var tendonIndex = helper.getTendon(i) - 1;
        if (tendonIndex >= tendonCount) {
          // This weight was set to a tendon that's no longer available, set the
          // weight to 0.
          helper.setWeight(tendonIndex, tendonCount, 0);
          wasValid = false;
        }
      }
    }
    return wasValid;
  }

  // Helper to set specific weights for sub-vertices.
  List<WeightedVertex> get weightedVertices => [TranslationWeight(this)];

  void clearWeight() {
    _weight?.remove();
  }

  @override
  bool validate() {
    return super.validate() && parent is Path;
  }
  // <- editor-only
}

// -> editor-only
class TranslationWeight extends WeightedVertex {
  final PathVertex<Weight> vertex;

  TranslationWeight(this.vertex);

  @override
  int get weightIndices => vertex.weight.indices;

  @override
  set weightIndices(int value) => vertex.weight.indices = value;

  @override
  int get weights => vertex.weight.values;

  @override
  set weights(int value) => vertex.weight.values = value;
}
// <- editor-only
