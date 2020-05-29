import 'package:rive/rive_core/component_dirt.dart';
import 'package:rive/rive_core/math/mat2d.dart';
import 'package:rive/rive_core/shapes/path.dart';
import 'package:rive/rive_core/shapes/path_vertex.dart';

class UserPath extends Path {
  bool _isClosed = false;
  final List<PathVertex> _vertices = [];
  @override
  bool get isClosed => _isClosed;
  set isClosed(bool val) {
    if (val != _isClosed) {
      _isClosed = val;
      addDirt(ComponentDirt.path);
    }
  }

  @override
  Mat2D get pathTransform => worldTransform;
  @override
  List<PathVertex> get vertices => _vertices;
}
