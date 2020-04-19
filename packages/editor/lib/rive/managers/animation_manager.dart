import 'dart:async';
import 'dart:collection';

import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:core/id.dart';
import 'package:meta/meta.dart';
import 'package:rive_core/animation/animation.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rxdart/rxdart.dart';

class AnimationManager with RiveFileDelegate {
  final OpenFileContext file;
  final _animationStreamControllers =
      HashMap<Id, BehaviorSubject<AnimationViewModel>>();
  final _animationsController =
      BehaviorSubject<Iterable<ValueStream<AnimationViewModel>>>();
  final _animations = <BehaviorSubject<AnimationViewModel>>[];
  final _selectedAnimation = BehaviorSubject<AnimationViewModel>();
  final _selectAnimationController = StreamController<AnimationViewModel>();

  AnimationManager({
    @required this.file,
  }) {
    file.core.objects.whereType<Animation>().map(_updateAnimation);
    _updateAnimations();
    file.core.addDelegate(this);
  }

  @override
  void onObjectAdded(Core object) {
    if (object is Animation) {
      _updateAnimation(object);
      debounce(_updateAnimations);
    }
  }

  @override
  void onObjectRemoved(Core object) {
    if (object is Animation) {
      var stream = _animationStreamControllers[object.id];
      if (stream != null) {
        _animationStreamControllers.remove(object.id);
      }
      if (_animations.remove(stream)) {
        debounce(_updateAnimations);
      }
    }
  }

  void _updateAnimations() {
    // For now just sort them by name.
    _animations.sort(
        (a, b) => a.value.animation.name.compareTo(b.value.animation.name));
    _animationsController.add(_animations);
  }

  BehaviorSubject<AnimationViewModel> _updateAnimation(Animation animation) {
    var animationStream = _animationStreamControllers[animation.id];
    if (animationStream == null) {
      _animationStreamControllers[animation.id] =
          animationStream = BehaviorSubject<AnimationViewModel>();
      _animations.add(animationStream);
    }
    animationStream
        .add(AnimationViewModel(animation: animation, icon: 'play-small'));
    return animationStream;
  }

  Stream<Iterable<ValueStream<AnimationViewModel>>> get animations =>
      _animationsController.stream;

  Sink<AnimationViewModel> get select => _selectAnimationController;

  /// Should this be an incoming stream? Only reason it isn't is because it has
  /// no parameters. All that the manager needs is a 'hey I want a new
  /// animation'.
  void makeLinearAnimation() {
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
      ..fps = 60;
    file.core.add(animation);
    file.core.captureJournalEntry();
  }

  void dispose() {
    cancelDebounce(_updateAnimations);
  }
}

class AnimationViewModel {
  final Animation animation;
  final String icon;

  AnimationViewModel({this.animation, this.icon});
}
