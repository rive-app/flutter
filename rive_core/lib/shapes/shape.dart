import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/src/generated/shapes/shape_base.dart';

export 'package:rive_core/src/generated/shapes/shape_base.dart';

class Shape extends ShapeBase {
  final Set<Path> paths = {};
  PathComposer _pathComposer;
  PathComposer get pathComposer => _pathComposer;
  set pathComposer(PathComposer value) {
    if (_pathComposer == value) {
      return;
    }
    _pathComposer = value;
    _pathComposer?.addDirt(ComponentDirt.path);
  }

  AABB _bounds = AABB();
  BoundsDelegate _delegate;
  AABB get bounds => _bounds;

  set bounds(AABB bounds) {
    if (AABB.areEqual(bounds, _bounds)) {
      return;
    }
    _bounds = bounds;
    _delegate?.boundsChanged();
  }

  bool addPath(Path path) {
    print("GOT PATH $path");
    _pathComposer?.addDirt(ComponentDirt.path);
    return paths.add(path);
  }

  @override
  void onAdded() {
    // Shape has been added and is clean (all artboards and ancestors of the
    // current hierarchy's components have resolved). This is a good opportunity
    // to self-heal Shapes that are missing PathComposers.
    if (_pathComposer == null) {
      var composer = PathComposer();
      context?.batchAdd(() {
        context.add(composer);
        appendChild(composer);
      });
    }
  }

  void pathChanged(Path path) {
    _pathComposer?.addDirt(ComponentDirt.path);
  }

  bool removePath(Path path) {
    _pathComposer?.addDirt(ComponentDirt.path);
    return paths.remove(path);
  }

  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is BoundsDelegate) {
      _delegate = to;
    } else {
      _delegate = null;
    }
  }
}
