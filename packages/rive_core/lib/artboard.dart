import 'dart:ui';

import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:core/id.dart';
import 'package:core/key_state.dart';
import 'package:flutter/foundation.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/bounds_delegate.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/component_dirt.dart';
import 'package:rive_core/draw_rules.dart';
import 'package:rive_core/draw_target.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_core/math/mat2d.dart';
import 'package:rive_core/math/vec2d.dart';
import 'package:rive_core/rive_animation_controller.dart';
import 'package:rive_core/shapes/clipping_shape.dart';
import 'package:rive_core/shapes/paint/shape_paint_mutator.dart';
import 'package:rive_core/shapes/shape_paint_container.dart';
import 'package:utilities/dependency_sorter.dart';

import 'package:rive_core/src/generated/artboard_base.dart';

export 'package:rive_core/src/generated/artboard_base.dart';

// -> editor-only
abstract class ArtboardDelegate extends BoundsDelegate {
  void markNameDirty();
}

class AnimationList extends FractionallyIndexedList<Animation> {
  @override
  FractionalIndex orderOf(Animation animation) {
    return animation.order;
  }

  @override
  void setOrderOf(Animation animation, FractionalIndex order) {
    animation.order = order;
  }
}
// <- editor-only

class Artboard extends ArtboardBase with ShapePaintContainer {
  // -> editor-only
  /// An event fired when the draw order changed,
  ArtboardDelegate _delegate;

  /// Event notified whenever the animations list changes.
  final Event animationsChanged = Event();

  @override
  String get defaultName => 'New Artboard';
  // <- editor-only

  /// Artboard are one of the few (only?) components that can be orphaned.
  @override
  bool get canBeOrphaned => true;

  final Path path = Path();
  List<Component> _dependencyOrder = [];
  final List<Drawable> _drawables = [];
  final List<DrawRules> _rules = [];
  List<DrawTarget> _sortedDrawRules;

  final Set<Component> _components = {};

  List<Drawable> get drawables => _drawables;

  final AnimationList _animations = AnimationList();

  /// List of animations in this artboard.
  AnimationList get animations => _animations;

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

  /// Walk the dependency tree and update components in order. Returns true if
  /// any component updated.
  bool updateComponents() {
    bool didUpdate = false;
    // -> editor-only
    if ((_dirt & ComponentDirt.naturalDrawOrder) != 0) {
      computeDrawOrder();
      _dirt &= ~ComponentDirt.naturalDrawOrder;
      didUpdate = true;
    }
    // <- editor-only
    if ((_dirt & ComponentDirt.drawOrder) != 0) {
      sortDrawOrder();
      _dirt &= ~ComponentDirt.drawOrder;
      didUpdate = true;
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

  /// Update any dirty components in this artboard.
  bool advance(double elapsedSeconds) {
    bool didUpdate = false;
    for (final controller in _animationControllers) {
      if (controller.isActive) {
        controller.apply(context, elapsedSeconds);
        didUpdate = true;
      }
    }
    return updateComponents() || didUpdate;
  }

  // -> editor-only
  @override
  void nameChanged(String from, String to) {
    _delegate?.markNameDirty();
  }
  // <- editor-only

  @override
  void heightChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
    invalidateStrokeEffects();
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
      var rect = Rect.fromLTWH(0, 0, width, height);
      path.reset();
      path.addRect(rect);
      // -> editor-only
      _delegate?.boundsChanged();
      // <- editor-only
    }
  }

  // -> editor-only

  /// Artboards shouldn't be parented to anything.
  @override
  bool validate() => parent == null;

  /// Artboards are exported as a base object in the file, so they never export
  /// in context of another artboard.
  @override
  bool exportsWith(Artboard artboard) {
    return false;
  }

  @override
  void userDataChanged(dynamic from, dynamic to) {
    if (to is ArtboardDelegate) {
      _delegate = to;
    } else {
      _delegate = null;
    }
  }
  // <- editor-only

  @override
  void widthChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
    invalidateStrokeEffects();
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
    // -> editor-only
    markNaturalDrawOrderDirty();
    // <- editor-only
  }

  /// Remove a component from the artboard and its various tracked lists of
  /// components.
  void removeComponent(Component component) {
    _components.remove(component);
    // -> editor-only
    markNaturalDrawOrderDirty();
    // <- editor-only
  }

  /// Let the artboard know that the drawables need to be resorted before
  /// drawing next.
  void markDrawOrderDirty() {
    if ((dirt & ComponentDirt.drawOrder) == 0) {
      context?.markNeedsAdvance();
      _dirt |= ComponentDirt.drawOrder;
    }
  }

  // -> editor-only

  /// Let the artboard know that the natural draw order needs to be re-computed.
  /// This happens when a rule is added, a child is moved in the hierarchy, or
  /// an object is added to the hierarchy.
  void markNaturalDrawOrderDirty() {
    if ((dirt & ComponentDirt.naturalDrawOrder) == 0) {
      context?.markNeedsAdvance();
      _dirt |= ComponentDirt.naturalDrawOrder;
    }
  }

  bool get isTranslucent =>
      fills.isEmpty ||
      fills.every((fill) => fill.isTranslucent || !fill.isVisible);
  // <- editor-only

  /// Draw the drawable components in this artboard.
  void draw(Canvas canvas) {
    for (final fill in fills) {
      fill.draw(canvas, path);
    }

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, width, height));
    // Get into artboard's world space. This is because the artboard draws
    // components in the artboard's space (in component lingo we call this world
    // space). The artboards themselves are drawn in the editor's world space,
    // which is the world space that is used by stageItems. This is a little
    // confusing and perhaps we should find a better wording for the transform
    // spaces. We used "world space" in components as that's the game engine
    // ratified way of naming the top-most transformation. Perhaps we should
    // rename those to artboardTransform and worldTransform is only reserved for
    // stageItems? The other option is to stick with 'worldTransform' in
    // components and use 'editor or stageTransform' for stageItems.
    canvas.translate(width * (originX ?? 0), height * (originY ?? 0));

    for (var drawable = _firstDrawable;
        drawable != null;
        drawable = drawable.prev) {
      drawable.draw(canvas);
    }
    canvas.restore();
  }

  // -> editor-only
  /// Artboard bounds (whether local or world) are always origin + size.
  @override
  AABB get localBounds => AABB.fromValues(0, 0, width, height);

  @override
  AABB get worldBounds => AABB.fromValues(x, y, x + width, y + height);
  // <- editor-only

  /// Our world transform is always the identity. Artboard defines world space.
  @override
  Mat2D get worldTransform => Mat2D();

  // -> editor-only
  @override
  void dependentIdsChanged(List<Id> from, List<Id> to) {}
  // <- editor-only

  @override
  void originXChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
  }

  @override
  void originYChanged(double from, double to) {
    addDirt(ComponentDirt.worldTransform);
  }

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
    controller.isActiveChanged.addListener(_onControllerPlayingChanged);
    _animationControllers.add(controller);
    if (controller.isActive) {
      context?.markNeedsAdvance();
    }
    return true;
  }

  /// Remove an animation controller form this artboard.
  bool removeController(RiveAnimationController controller) {
    assert(controller != null);
    if (_animationControllers.remove(controller)) {
      controller.isActiveChanged.removeListener(_onControllerPlayingChanged);
      controller.dispose();
      return true;
    }
    return false;
  }

  void _onControllerPlayingChanged() => context?.markNeedsAdvance();

  @override
  void onFillsChanged() {}

  @override
  void onPaintMutatorChanged(ShapePaintMutator mutator) {}

  @override
  void onStrokesChanged() {}

  // -> editor-only

  /// Rebuild the dependencies for any clipping shape in the artboard. This is
  /// an editor-only operation that easily lets the system update dependencies
  /// for clipping shapes.
  void rebuildClippingShapeDependencies() {
    for (final component in _components) {
      if (component.coreType == ClippingShapeBase.typeKey) {
        (component as ClippingShape).markRebuildDependencies();
      }
    }
  }

  // Hacking in the draw order key state by emulating what animated objects do
  // with their key state properties, but we do it for the Drawable's drawOrder
  // property. N.B. we don't use the same core eventing for key state changing,
  // instead we use a really simple value notifier.
  final ValueNotifier<KeyState> _drawOrderKeyState =
      ValueNotifier<KeyState>(KeyState.none);
  ValueListenable<KeyState> get drawOrderKeyStateListenable =>
      _drawOrderKeyState;
  KeyState get drawOrderKeyState => _drawOrderKeyState.value;
  set drawOrderKeyState(KeyState value) {
    _drawOrderKeyState.value = value;
  }

  /// Convert artboard space bounds into world bounds. Really only matters in
  /// the editor, in the runtimes the world is the artboard space.
  AABB transformBounds(AABB bounds) {
    // TODO: handle invert y option
    return bounds.translate(originWorld);
  }

  Mat2D transform(Mat2D mat) {
    // TODO: handle invert y option
    return Mat2D.translate(Mat2D(), mat, originWorld);
  }

  // <- editor-only
  @override
  Vec2D get worldTranslation => Vec2D();

  Drawable _firstDrawable;

  void computeDrawOrder() {
    _drawables.clear();
    _rules.clear();
    buildDrawOrder(_drawables, null, _rules);
    // Build rule dependencies. In practice this'll need to happen anytime a
    // target drawable is changed or rule is added/removed.
    var root = DrawTarget();
    // Make sure all dependents are empty.
    for (final nodeRules in _rules) {
      for (final target in nodeRules.targets) {
        target.dependents.clear();
      }
    }

    // Now build up the dependencies.
    for (final nodeRules in _rules) {
      for (final target in nodeRules.targets) {
        // -> editor-only
        target.ruleState = target.drawable != null
            ? DrawRuleState.valid
            : DrawRuleState.noTarget;
        // <- editor-only
        root.dependents.add(target);
        var dependentRules = target.drawable?.flattenedDrawRules;
        if (dependentRules != null) {
          for (final dependentRule in dependentRules.targets) {
            dependentRule.dependents.add(target);
          }
        }
      }
    }
    // -> editor-only
    var sorter = TarjansDependencySorter<Component>();
    // <- editor-only
    // -> runtime-only
    // var sorter = DependencySorter<Component>();
    // <- runtime-only

    _sortedDrawRules = sorter.sort(root).cast<DrawTarget>().skip(1).toList();
    // -> editor-only
    if (sorter.cycleNodes.isNotEmpty) {
      for (final invalidRule in sorter.cycleNodes) {
        (invalidRule as DrawTarget).ruleState = DrawRuleState.cycle;
      }
    }
    // <- editor-only

    sortDrawOrder();
  }

  void sortDrawOrder() {
    // Clear out rule first/last items.
    for (final rule in _sortedDrawRules) {
      rule.first = rule.last = null;
    }

    _firstDrawable = null;
    Drawable lastDrawable;
    for (final drawable in _drawables) {
      var rules = drawable.flattenedDrawRules;
      // -> editor-only
      while (rules != null &&
          rules.activeTarget != null &&
          rules.activeTarget.ruleState != DrawRuleState.valid) {
        rules = rules.parentRules;
      }
      // <- editor-only
      var target = rules?.activeTarget;
      if (target != null) {
        if (target.first == null) {
          target.first = target.last = drawable;
          drawable.prev = drawable.next = null;
        } else {
          target.last.next = drawable;
          drawable.prev = target.last;
          target.last = drawable;
          drawable.next = null;
        }
      } else {
        drawable.prev = lastDrawable;
        drawable.next = null;
        if (lastDrawable == null) {
          lastDrawable = _firstDrawable = drawable;
        } else {
          lastDrawable.next = drawable;
          lastDrawable = drawable;
        }
      }
    }

    for (final rule in _sortedDrawRules) {
      if (rule.first == null) {
        continue;
      }
      switch (rule.placement) {
        case DrawTargetPlacement.before:
          if (rule.drawable.prev != null) {
            rule.drawable.prev.next = rule.first;
            rule.first.prev = rule.drawable.prev;
          }
          if (rule.drawable == _firstDrawable) {
            _firstDrawable = rule.first;
          }
          rule.drawable.prev = rule.last;
          rule.last.next = rule.drawable;
          break;
        case DrawTargetPlacement.after:
          if (rule.drawable.next != null) {
            rule.drawable.next.prev = rule.last;
            rule.last.next = rule.drawable.next;
          }
          if (rule.drawable == lastDrawable) {
            lastDrawable = rule.last;
          }
          rule.drawable.next = rule.first;
          rule.first.prev = rule.drawable;
          break;
      }
    }

    _firstDrawable = lastDrawable;
    // -> editor-only

    // iterate all the drawables and give them their actual draw order which the
    // stage uses.
    int order = 0;
    for (var drawable = _firstDrawable;
        drawable != null;
        drawable = drawable.prev) {
      drawable.drawOrder = order++;
    }

    // <- editor-only
  }
}
