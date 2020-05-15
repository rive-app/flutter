import 'dart:ui';

import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:core/id.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/rive_animation_controller.dart';
import 'package:rive_core/shapes/paint/fill.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:rive_core/transform_space.dart';
import 'package:utilities/dependency_sorter.dart';

import 'component.dart';
import 'component_dirt.dart';
import 'src/generated/artboard_base.dart';

export 'src/generated/artboard_base.dart';

abstract class ArtboardDelegate extends BoundsDelegate {
  void markNameDirty();
}

class _AnimationList extends FractionallyIndexedList<Animation> {
  @override
  FractionalIndex orderOf(Animation animation) {
    return animation.order;
  }

  @override
  void setOrderOf(Animation animation, FractionalIndex order) {
    animation.order = order;
  }
}

class DrawableList extends FractionallyIndexedList<Drawable> {
  @override
  FractionalIndex orderOf(Drawable drawable) {
    return drawable.drawOrder;
  }

  @override
  void setOrderOf(Drawable drawable, FractionalIndex order) {
    drawable.drawOrder = order;
  }
}

class Artboard extends ArtboardBase with ShapePaintContainer {
  // -> editor-only
  /// An event fired when the draw order changed,
  final Event drawOrderChanged = Event();
  // <- editor-only

  /// Artboard are one of the few (only?) components that can be orphaned.
  @override
  bool get canBeOrphaned => true;

  final Path path = Path();
  ArtboardDelegate _delegate;
  List<Component> _dependencyOrder = [];
  final DrawableList _drawables = DrawableList();
  final Set<Component> _components = {};

  DrawableList get drawables => _drawables;

  // -> editor-only
  /// Event notified whenever the animations list changes.
  final Event animationsChanged = Event();
  // <- editor-only
  final _AnimationList _animations = _AnimationList();

  /// List of animations in this artboard.
  _AnimationList get animations => _animations;

  /// Does this artboard have animations?
  bool get hasAnimations => _animations.isNotEmpty;

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
    bool didUpdate = false;
    for (final controller in _animationControllers) {
      if (controller.isPlaying) {
        controller.apply(context, elapsedSeconds);
        didUpdate = true;
      }
    }

    if ((_dirt & ComponentDirt.drawOrder) != 0) {
      _drawables.sortFractional();
      _dirt &= ~ComponentDirt.drawOrder;
      // -> editor-only
      drawOrderChanged.notify();
      // <- editor-only
    }
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
    return didUpdate;
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
    var optimistic = DependencySorter<Component>();
    var order = optimistic.sort(this);
    if (order == null) {
      // cycle detected, use a more robust solver
      var robust = TarjansDependencySorter<Component>();
      order = robust.sort(this);
    }

    _dependencyOrder = order;
    for (final component in _dependencyOrder) {
      component.graphOrder = graphOrder++;
      // component.dirt = 255;
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
    addDirt(ComponentDirt.worldTransform);
  }

  @override
  void xChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
  }

  @override
  void yChanged(double from, double to) {
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

      // -> editor-only
      if (component.drawOrder == null && !_drawables.validateFractional()) {
        // Draw order was missing, so force validate it (change the null draw
        // orders) and hence we re=sort. This should only happen on creation or
        // patchup of corrupt files.

        // We sort immediately in-case more null drawOrder items are added.
        _drawables.sortFractional();
      }
      // <- editor-only
      markDrawOrderDirty();
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

  /// Let the artboard know that the drawables need to be resorted before
  /// drawing next.
  void markDrawOrderDirty() {
    if ((dirt & ComponentDirt.drawOrder) == 0) {
      context?.markNeedsAdvance();
      _dirt |= ComponentDirt.drawOrder;
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

  @override
  void dependentIdsChanged(List<Id> from, List<Id> to) {}

  @override
  void originXChanged(double from, double to) {}

  @override
  void originYChanged(double from, double to) {}

  /// Called by rive_core to add an Animation to an Artboard. This should be
  /// @internal when it's supported.
  bool internalAddAnimation(Animation animation) {
    if (_animations.contains(animation)) {
      return false;
    }
    _animations.add(animation);
    // -> editor-only - We don't care if animations are ordered in the runtime.
    markAnimationOrderDirty();
    // <- editor-only
    return true;
  }

  /// Called by rive_core to remove an Animation from an Artboard. This should
  /// be @internal when it's supported.
  bool internalRemoveAnimation(Animation animation) {
    bool removed = _animations.remove(animation);
    // -> editor-only
    if (removed) {
      markAnimationOrderDirty();
    }
    // <- editor-only
    return removed;
  }

  // -> editor-only
  /// Schedule re-sorting the animations list.
  void markAnimationOrderDirty() {
    // We don't actually track this with the component dirty state as it has no
    // bearing at runtime and shouldn't clutter our runtime pipeline.
    debounce(_orderAnimations);
  }
  // <- editor-only

  // -> editor-only - Thinking about introducing some comment syntax to remove
  // anything between editor-only markers from the runtime code. Kind of hoping
  // the runtime code can be generated from the rive_core code.
  void _orderAnimations() {
    if (!_animations.validateFractional()) {
      // List wasn't valid for some reason, it was patched up so save the change
      // and don't allow undoing.
      context?.captureJournalEntry(record: false);
    }
    _animations.sortFractional();
    animationsChanged.notify();
  }
  // <- editor-only

  /// The animation controllers that are called back whenever the artboard
  /// advances.
  final Set<RiveAnimationController> _animationControllers = {};

  /// Add an animation controller to this artboard. Playing will be scheduled if
  /// it's already playing.
  bool addController(RiveAnimationController controller) {
    assert(controller != null);
    if (_animationControllers.contains(controller) ||
        !controller.init(context)) {
      return false;
    }
    controller.isPlayingChanged.addListener(_onControllerPlayingChanged);
    _animationControllers.add(controller);
    if (controller.isPlaying) {
      context?.markNeedsAdvance();
    }
    return true;
  }

  /// Remove an animation controller form this artboard.
  bool removeController(RiveAnimationController controller) {
    assert(controller != null);
    if (_animationControllers.remove(controller)) {
      controller.isPlayingChanged.removeListener(_onControllerPlayingChanged);
      controller.dispose();
      return true;
    }
    return false;
  }

  void _onControllerPlayingChanged() => context?.markNeedsAdvance();
}
