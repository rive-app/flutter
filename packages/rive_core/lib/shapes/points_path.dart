import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/shapes/path_vertex.dart';
import 'package:rive_core/src/generated/shapes/points_path_base.dart';

export 'package:rive_core/src/generated/shapes/points_path_base.dart';

class PointsPath extends PointsPathBase {
  final List<PathVertex> _vertices = [];

  PointsPath() {
    isClosed = false;
  }

  @override
  Mat2D get pathTransform => worldTransform;

  @override
  List<PathVertex> get vertices => _vertices;

  void addVertex(PathVertex v) {
    _vertices.add(v);
    appendChild(v);
    addDirt(ComponentDirt.path);
  }

  void removeVertex(PathVertex v) {
    final removed = _vertices.remove(v);
    children.remove(v);
    if (!removed) {
      throw ArgumentError.value(v, "PathVertex wasn't in this Path??");
    }
    addDirt(ComponentDirt.path);
  }
}
