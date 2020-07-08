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

class PointsPath extends PointsPathBase {
  final List<PathVertex> _vertices = [];

  PointsPath() {
    isClosed = false;
  }

  // When bound to bones pathTransform should be the identity as it'll already
  // be in world space.
  @override
  Mat2D get pathTransform => worldTransform;

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

  // -> editor-only
  @override
  void update(int dirt) {
    // Vertices just changed, make sure they're in order.
    if (dirt & ComponentDirt.vertices != 0) {
      _vertices.sort((a, b) => a.childOrder.compareTo(b.childOrder));
    }
    super.update(dirt);
  }
  // <- editor-only
}
