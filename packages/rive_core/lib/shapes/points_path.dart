import 'package:rive_core/component.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/shapes/straight_vertex.dart';
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

  @override
  Mat2D get pathTransform => worldTransform;

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
    switch (child.coreType) {
      case StraightVertexBase.typeKey:
        if (!_vertices.contains(child)) {
          _vertices.add(child as StraightVertex);
          markPathDirty();
        }
        break;
    }
  }

  @override
  void childRemoved(Component child) {
    super.childRemoved(child);
    switch (child.coreType) {
      case StraightVertexBase.typeKey:
        if (_vertices.remove(child as StraightVertex)) {
          markPathDirty();
        }
        break;
    }
  }

  @override
  void isClosedChanged(bool from, bool to) {
    markPathDirty();
  }
}
