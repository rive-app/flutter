import 'dart:ui';

import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_core/transform_space.dart';

import 'component.dart';
import 'component_dirt.dart';
import 'dependency_sorter.dart';
import 'src/generated/artboard_base.dart';

export 'src/generated/artboard_base.dart';

abstract class ArtboardDelegate extends BoundsDelegate {
  void markNameDirty();
}

class Artboard extends ArtboardBase with ShapePaintContainer {
  final Path path = Path();
  ArtboardDelegate _delegate;
  List<Component> _dependencyOrder = [];
  final List<Drawable> _drawables = [];
  final Set<Component> _components = {};
  int _dirtDepth = 0;
  int _dirt = 255;

  void forEachComponent(void Function(Component) callback) =>
      _components.forEach(callback);

  @override
  Artboard get artboard => this;

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
  void childAdded(Component child) {
    super.childAdded(child);
    if (child is Fill) {
      addFill(child);
    }
  }

  @override
  void nameChanged(String from, String to) {
    super.nameChanged(from, to);
    _delegate?.markNameDirty();
  }

  @override
  void childRemoved(Component child) {
    super.childRemoved(child);
    if (child is Fill) {
      removeFill(child);
    }
  }

  @override
  void heightChanged(double from, double to) {
    super.heightChanged(from, to);

    addDirt(ComponentDirt.worldTransform);
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
  void update(int dirt) {
    if (dirt & ComponentDirt.worldTransform != 0) {
      path.reset();
      path.addRect(computeBounds(TransformSpace.world));
      _delegate?.boundsChanged();
    }
  }

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

    addDirt(ComponentDirt.worldTransform);
  }

  @override
  void xChanged(double from, double to) {
    super.xChanged(from, to);

    addDirt(ComponentDirt.worldTransform);
  }

  @override
  void yChanged(double from, double to) {
    super.yChanged(from, to);

    addDirt(ComponentDirt.worldTransform);
  }

  Vec2D renderTranslation(Vec2D worldTranslation) {
    final wt = originWorld;
    return Vec2D.add(Vec2D(), worldTranslation, wt);
  }

  /// Adds a component to the artboard. Good place for the artboard to check for
  /// components it'll later need to do stuff with (like draw them or sort them
  /// when the draw order changes).
  void addComponent(Component component) {
    if (!_components.add(component)) {
      return;
    }
    if (component is Drawable) {
      assert(!_drawables.contains(component));
      _drawables.add(component);
    }
  }

  /// Remove a component from the artboard and its various tracked lists of
  /// components.
  void removeComponent(Component component) {
    _components.remove(component);
    if (component is Drawable) {
      _drawables.remove(component);
    }
  }

  /// Draw the drawable components in this artboard.
  void draw(Canvas canvas) {
    for (final fill in fills) {
      fill.draw(canvas, path);
    }
    for (final drawable in _drawables) {
      drawable.draw(canvas);
    }
  }

  /// Artboard bounds (whether local or world) are always origin + size.
  @override
  Rect computeBounds(TransformSpace space) =>
      Rect.fromLTWH(0, 0, width, height);

  /// Our world transform is always the identity. Artboard defines world space.
  @override
  Mat2D get worldTransform => Mat2D();
}
