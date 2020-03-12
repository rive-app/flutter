import 'package:rive_core/math/vec2d.dart';

import 'component.dart';
import 'component_dirt.dart';
import 'dependency_sorter.dart';
import 'math/mat2d.dart';
import 'src/generated/artboard_base.dart';

export 'src/generated/artboard_base.dart';

class Artboard extends ArtboardBase {
  ArtboardDelegate _delegate;
  List<Component> _dependencyOrder = [];

  int _dirtDepth = 0;
  int _dirt = 255;

  @override
  Artboard get artboard => this;

  @override
  Mat2D get renderTransform => Mat2D.fromTranslation(originWorld);

  Vec2D get originWorld {
    return Vec2D.fromValues(
        x + width * (originX ?? 0), y + height * (originY ?? 0));
  }

  /// Update any dirty components in this artboard.
  bool advance(double elapsedSeconds) {
    if ((_dirt & ComponentDirt.components) != 0) {
      const int maxSteps = 100;
      int step = 0;
      int count = _dependencyOrder.length;
      while ((_dirt & ComponentDirt.components) != 0 && step < maxSteps) {
        _dirt &= ~ComponentDirt.components;
        // Track dirt depth here so that if something else marks
        // dirty, we restart.
        for (int i = 0; i < count; i++) {
          Component component = _dependencyOrder[i];
          _dirtDepth = i;
          int d = component.dirt;
          if (d == 0) {
            continue;
          }
          component.dirt = 0;
          component.update(d);
          if (_dirtDepth < i) {
            break;
          }
        }
        step++;
      }
      return true;
    }
    return false;
  }

  @override
  void heightChanged(double from, double to) {
    super.heightChanged(from, to);
    _delegate?.markBoundsDirty();
  }

  void onComponentDirty(Component component) {
    if ((dirt & ComponentDirt.components) == 0) {
      context?.markNeedsAdvance();
      _dirt |= ComponentDirt.components;
    }

    /// If the order of the component is less than the current dirt depth,
    /// update the dirt depth so that the update loop can break out early and
    /// re-run (something up the tree is dirty).
    if (component.graphOrder < _dirtDepth) {
      _dirtDepth = component.graphOrder;
    }
  }

  @override
  bool resolveArtboard() => true;

  /// Sort the DAG for resolution in order of dependencies such that dependent
  /// compnents process after their dependencies.
  void sortDependencies() {
    var optimistic = DependencySorter();
    var order = optimistic.sort(this);
    if (order == null) {
      // cycle detected, use a more robust solver
      var robust = TarjansDependencySorter();
      order = robust.sort(this);
    }
    _dependencyOrder = order;
    for (final component in _dependencyOrder) {
      component.graphOrder = graphOrder++;
      component.dirt = 255;
    }

    _dirt |= ComponentDirt.components;
  }

  @override
  void update(int dirt) {}

  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is ArtboardDelegate) {
      _delegate = to;
    } else {
      _delegate = null;
    }
  }

  @override
  void widthChanged(double from, double to) {
    super.widthChanged(from, to);
    _delegate?.markBoundsDirty();
  }

  @override
  void xChanged(double from, double to) {
    super.xChanged(from, to);
    _delegate?.markBoundsDirty();
  }

  @override
  void yChanged(double from, double to) {
    super.yChanged(from, to);
    _delegate?.markBoundsDirty();
  }

  Vec2D renderTranslation(Vec2D worldTranslation) {
    final wt = originWorld;
    return Vec2D.add(Vec2D(), worldTranslation, wt);
  }
}

abstract class ArtboardDelegate {
  void markBoundsDirty();
}
