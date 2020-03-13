import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/path.dart';
import 'package:rive_core/shapes/path_composer.dart';
import 'package:rive_core/src/generated/shapes/shape_base.dart';

export 'package:rive_core/src/generated/shapes/shape_base.dart';

class Shape extends ShapeBase {
  final Set<Fill> fills = {};
  final Set<Path> paths = {};
  final Event fillsChanged = Event();

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

  @override
  void childAdded(Component child) {
    super.childAdded(child);
    if (child is Fill) {
      if (fills.add(child)) {
        fillsChanged.notify();
      }
    }
  }

  @override
  void childRemoved(Component child) {
    super.childRemoved(child);
    if (child is Fill) {
      if (fills.remove(child)) {
        fillsChanged.notify();
      }
    }
  }

  bool addPath(Path path) {
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

  @override
  void paint(Canvas canvas) {
    assert(_pathComposer != null);

    for (final fill in fills) {
      // _pathComposer.uiPath.fillType = fill.fillRule;
      if (!fill.isVisible) {
        continue;
      }
      canvas.drawPath(_pathComposer.uiPath, fill.paint);
    }
  }
}
