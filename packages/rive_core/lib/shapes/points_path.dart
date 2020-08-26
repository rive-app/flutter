import 'package:rive_core/bones/skinnable.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/src/generated/shapes/points_path_base.dart';

export 'package:rive_core/src/generated/shapes/points_path_base.dart';

enum PointsPathEditMode {
  off,
  creating,
  editing,
}

class PointsPath extends PointsPathBase with Skinnable {
  final List<PathVertex> _vertices = [];

  PointsPath() {
    isClosed = false;
  }

  // When bound to bones pathTransform should be the identity as it'll already
  // be in world space.
  @override
  Mat2D get pathTransform => skin != null ? Mat2D() : worldTransform;

  // When bound to bones inversePathTransform should be the identity.
  @override
  Mat2D get inversePathTransform => inverseWorldTransform;

  @override
  List<PathVertex> get vertices => _vertices;

  // -> editor-only
  PointsPathEditMode get editingMode =>
      PointsPathEditMode.values[editingModeValue];
  set editingMode(PointsPathEditMode value) => editingModeValue = value.index;
  @override
  void editingModeValueChanged(int from, int to) {}
  // <- editor-only

  @override
  void childAdded(Component child) {
    super.childAdded(child);
    if (child is PathVertex && !_vertices.contains(child)) {
      _vertices.add(child);
      markPathDirty();
      addDirt(ComponentDirt.vertices);
    }
  }

  @override
  void childRemoved(Component child) {
    super.childRemoved(child);
    if (child is PathVertex && _vertices.remove(child)) {
      markPathDirty();
    }
  }

  @override
  void isClosedChanged(bool from, bool to) {
    markPathDirty();
  }

  @override
  void buildDependencies() {
    super.buildDependencies();

    // Depend on the skin, if we have it. This works because the skin is not a
    // node so we have no dependency on our parent yet (which would cause a
    // dependency cycle).
    skin?.addDependent(this);
  }

  // -> editor-only
  @override
  void onDirty(int mask) {
    // When we receive path dirt, we'll be rebuilding the draw commands for the
    // path. If we have skin, we'll also be deforming the vertices before
    // building the commands. We can take this opportunity to tell the vertices
    // that they will need to recompute their bounds (vertices recompute bounds
    // when they receive worldTransform dirt).
    if (dirt & ComponentDirt.path != 0 && skin != null) {
      for (final child in children) {
        child.addDirt(ComponentDirt.worldTransform);
      }
    }
  }
  // <- editor-only

  @override
  void markPathDirty() {
    // Make sure the skin gets marked dirty too.
    skin?.addDirt(ComponentDirt.path);
    super.markPathDirty();
  }

  @override
  void markSkinDirty() => super.markPathDirty();

  // -> editor-only
  @override
  void update(int dirt) {
    // Vertices just changed, make sure they're in order.
    if (dirt & ComponentDirt.vertices != 0) {
      _vertices.sort((a, b) => a.childOrder.compareTo(b.childOrder));
    }
    if (dirt & ComponentDirt.path != 0) {
      // Before calling super (which will build the path) make sure to deform
      // things if necessary. We depend on the skin which assures us that the
      // boneTransforms are up to date.
      skin?.deform(_vertices);
    }
    // Finally call super.update so the path commands can actually be rebuilt
    // (when ComponentDirt.path is set).
    super.update(dirt);
  }

  @override
  void initWeights() {
    for (final vertex in _vertices) {
      vertex.initWeight();
    }
  }

  @override
  void clearWeights() {
    for (final vertex in _vertices) {
      vertex.clearWeight();
    }
  }
  // <- editor-only
}
