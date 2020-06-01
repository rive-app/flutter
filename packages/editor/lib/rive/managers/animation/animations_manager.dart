import 'dart:async';
import 'dart:collection';

import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:core/id.dart';
import 'package:meta/meta.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/animation/keyed_object.dart';
import 'package:rive_core/animation/keyed_property.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rxdart/rxdart.dart';

/// Animation type that can be created by the [AnimationsManager].
enum AnimationType { linear }
enum AnimationOrder { aToZ, zToA, custom }

/// A manager for a file's list of animations allowing creating and updating
/// them.
class AnimationsManager {
  final Artboard activeArtboard;
  final _animationStreamControllers =
      HashMap<Id, BehaviorSubject<AnimationViewModel>>();
  final _animationsController =
      BehaviorSubject<Iterable<ValueStream<AnimationViewModel>>>();
  final _selectedAnimationStream = BehaviorSubject<AnimationViewModel>();
  final _selectAnimationController = StreamController<AnimationViewModel>();
  final _deleteController = StreamController<AnimationViewModel>();
  final _renameController = StreamController<RenameAnimationModel>();
  final _animations = <BehaviorSubject<AnimationViewModel>>[];

  /// Input to create new animations.
  final _createController = StreamController<AnimationType>();

  /// Input to sort animations.
  final _orderController = StreamController<AnimationOrder>();

  /// Input for animation hover.
  final _mouseOverController = StreamController<AnimationViewModel>();
  final _mouseOutController = StreamController<AnimationViewModel>();
  Animation _hoveredAnimation;
  Animation _selectedAnimation;

  AnimationsManager({
    @required this.activeArtboard,
  }) {
    activeArtboard.context.startAnimating();
    activeArtboard.animationsChanged.addListener(_updateAnimations);
    // Initialize the list of animations.
    _updateAnimations();

    // Listen for animation hover changes.
    _mouseOverController.stream.listen(_onMouseOver);
    _mouseOutController.stream.listen(_onMouseOut);

    // Listen for animation selection changes.
    _selectAnimationController.stream.listen(_onSelect);

    // Listen for delete requests.
    _deleteController.stream.listen(_onDelete);

    // Listen for rename requests.
    _renameController.stream.listen(_onRename);

    _createController.stream.listen((type) {
      switch (type) {
        case AnimationType.linear:
          _makeLinearAnimation();
          break;
      }
    });

    _orderController.stream.listen(_onOrder);

    if (_animationStreamControllers.isEmpty) {
      /// Push through a null (none) selected animation if we don't have any
      /// animations at all.
      _selectedAnimationStream.add(null);
      // Create a default animation
      _createDefaultAnimation();
    }
  }

  void _onOrder(AnimationOrder order) {
    switch (order) {
      case AnimationOrder.aToZ:
        activeArtboard.animations.sort((a, b) => a.name.compareTo(b.name));
        break;
      case AnimationOrder.zToA:
        activeArtboard.animations.sort((a, b) => b.name.compareTo(a.name));
        break;
      case AnimationOrder.custom:
        // Expect the implementor to have custom set the fractional indices.
        activeArtboard.context.captureJournalEntry();
        return;
    }
    activeArtboard.animations.setFractionalIndices();
    activeArtboard.context.captureJournalEntry();
  }

  void _onRename(RenameAnimationModel model) {
    assert(model?.viewModel?.animation?.context != null);
    var core = model.viewModel.animation.context;

    model.viewModel.animation.name = model.name;
    core.captureJournalEntry();
  }

  void _onDelete(AnimationViewModel viewModel) {
    if (viewModel.animation is LinearAnimation) {
      _deleteLinearAnimation(viewModel.animation as LinearAnimation);
    }
  }

  void _deleteLinearAnimation(LinearAnimation animation) {
    assert(animation.context != null);
    // delete all keyedObjects, keyedProperties, and keys themselves.
    final file = animation.context;
    List<KeyedObject>.from(animation.keyedObjects, growable: false)
        .forEach((keyedObject) {
      List<KeyedProperty>.from(
        keyedObject.keyedProperties,
        growable: false,
      ).forEach((keyedProperty) {
        List<KeyFrame>.from(
          keyedProperty.keyframes,
          growable: false,
        ).forEach(file.removeObject);
        file.removeObject(keyedProperty);
      });
      file.removeObject(keyedObject);
    });
    file.removeObject(animation);
    file.captureJournalEntry();
  }

  void _setHovered(AnimationViewModel animationViewModel) {
    // Update current hover and track previous to update both viewmodels.
    var previouslyHovered = _hoveredAnimation;
    _hoveredAnimation = animationViewModel?.animation;

    // Update changed viewmodels.
    if (previouslyHovered != null) {
      _updateAnimationSelectionState(previouslyHovered);
    }
    if (_hoveredAnimation != null) {
      _updateAnimationSelectionState(_hoveredAnimation);
    }
  }

  void _onMouseOver(AnimationViewModel animationViewModel) =>
      _setHovered(animationViewModel);

  void _onMouseOut(AnimationViewModel animationViewModel) {
    if (animationViewModel.animation == _hoveredAnimation) {
      _setHovered(null);
    }
  }

  void _onSelect(AnimationViewModel animationViewModel) {
    // Update current selection and track previous to update both viewmodels.
    var previouslySelected = _selectedAnimation;
    _selectedAnimation = animationViewModel?.animation;

    // Update changed viewmodels.
    if (previouslySelected != null) {
      _updateAnimationSelectionState(previouslySelected);
    }
    if (_selectedAnimation != null) {
      _updateAnimationSelectionState(_selectedAnimation);
    }
  }

  // Call this internally whenever the selected/hovered state of an animation is
  // changed (we call this for the incoming and outgoing viewmodels such that
  // they are both updated). If there is not outgoing/incoming this call should
  // be skipped for that view model (like selecting when no previous selection
  // was available).
  void _updateAnimationSelectionState(Animation animation) {
    // ignore: close_sinks, false positive
    var viewModelStream = _animationStreamControllers[animation.id];
    if (viewModelStream == null) {
      return;
    }
    viewModelStream.add(viewModelStream.value.copyWith(
        selectionState: _hoveredAnimation == animation
            ? SelectionState.hovered
            : _selectedAnimation == animation
                ? SelectionState.selected
                : SelectionState.none));

    // Propagate to the selected view model stream if this is the one.
    if (_selectedAnimation == animation) {
      _selectedAnimationStream.add(viewModelStream.value);
    }
  }

  // Internally call this whenever the list of animations needs to be re-sorted.
  void _updateAnimations() {
    for (final animation in _animations) {
      animation.close();
    }
    _animations.clear();
    _animationStreamControllers.clear();

    var animations = activeArtboard?.animations;
    animations.forEach(_updateAnimation);

    _animationsController.add(_animations);

    // If we just added our first animation, make it the selected one.
    if (_selectedAnimation == null && _animations.isNotEmpty) {
      _selectAnimationController.add(_animations.first.value);
    }
  }

  BehaviorSubject<AnimationViewModel> _updateAnimation(Animation animation) {
    var animationStream = _animationStreamControllers[animation.id];
    if (animationStream == null) {
      _animationStreamControllers[animation.id] =
          animationStream = BehaviorSubject<AnimationViewModel>();
      _animations.add(animationStream);
    }
    animationStream.add(AnimationViewModel(
      animation: animation,
      icon: PackedIcon.playSmall,
    ));
    return animationStream;
  }

  Stream<Iterable<ValueStream<AnimationViewModel>>> get animations =>
      _animationsController.stream;

  Sink<AnimationViewModel> get select => _selectAnimationController;
  Sink<AnimationViewModel> get mouseOver => _mouseOverController;
  Sink<AnimationViewModel> get mouseOut => _mouseOutController;
  Sink<AnimationType> get create => _createController;
  Sink<AnimationViewModel> get delete => _deleteController;
  Sink<RenameAnimationModel> get rename => _renameController;
  Sink<AnimationOrder> get order => _orderController;
  Stream<AnimationViewModel> get selectedAnimation => _selectedAnimationStream;

  void _makeLinearAnimation() {
    assert(activeArtboard != null);
    var regex = RegExp(r"Untitled ([0-9])+");
    int maxUntitled = 0;
    for (final animationStream in _animationStreamControllers.values) {
      var matches = regex.allMatches(animationStream.value.animation.name);
      for (final match in matches) {
        var num = int.parse(match.group(1));
        if (num > maxUntitled) {
          maxUntitled = num;
        }
      }
    }
    var animation = LinearAnimation()
      ..name = 'Untitled ${maxUntitled + 1}'
      ..fps = 60
      ..artboardId = activeArtboard.id;
    var core = activeArtboard.context;
    core.addObject(animation);
    core.captureJournalEntry();
  }

  /// Create a default animation if the artboard has none
  bool _createDefaultAnimation() {
    if (!activeArtboard.hasAnimations) {
      _makeLinearAnimation();
      return true;
    }
    return false;
  }

  /// Cleanup the manager.
  void dispose() {
    activeArtboard.context.stopAnimating();
    activeArtboard.animationsChanged.removeListener(_updateAnimations);
    // Make sure to close all streams and cancel any debounced methods.
    _renameController.close();
    _deleteController.close();
    _createController.close();
    _orderController.close();
    _mouseOverController.close();
    _mouseOutController.close();
    _selectedAnimationStream.close();
    _selectAnimationController.close();
    for (final animationStream in _animationStreamControllers.values) {
      animationStream.close();
    }
    _animations.clear();
    _animationStreamControllers.clear();
    cancelDebounce(_updateAnimations);
  }
}

/// View model for an animation containing data regarding selection/hover state,
/// icon to display in the animation list, and a reference to the animation
/// itself.
@immutable
class AnimationViewModel {
  final Animation animation;
  final Iterable<PackedIcon> icon;
  final SelectionState selectionState;

  const AnimationViewModel({
    this.animation,
    this.icon,
    this.selectionState = SelectionState.none,
  });

  AnimationViewModel copyWith({
    Animation animation,
    Iterable<PackedIcon> icon,
    SelectionState selectionState,
  }) =>
      AnimationViewModel(
        animation: animation ?? this.animation,
        icon: icon ?? this.icon,
        selectionState: selectionState ?? this.selectionState,
      );
}

/// A data model sent to the manager to trigger a rename of an animation.
class RenameAnimationModel {
  final String name;
  final AnimationViewModel viewModel;

  RenameAnimationModel(this.name, this.viewModel);
}
