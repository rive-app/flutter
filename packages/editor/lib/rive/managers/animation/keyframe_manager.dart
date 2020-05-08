import 'dart:async';
import 'dart:collection';

import 'package:core/debounce.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_editor/rive/managers/animation/animation_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:utilities/list_equality.dart';

class KeyFrameManager extends AnimationManager {
  final OpenFileContext activeFile;
  final _selection =
      BehaviorSubject<HashSet<KeyFrame>>.seeded(HashSet<KeyFrame>());
  final _selectionController = StreamController<HashSet<KeyFrame>>();
  Sink<HashSet<KeyFrame>> get changeSelection => _selectionController;
  ValueStream<HashSet<KeyFrame>> get selection => _selection;

  final _interpolationType = BehaviorSubject<KeyFrameInterpolation>();
  ValueStream<KeyFrameInterpolation> get interpolationType =>
      _interpolationType;
  final _interpolationController = StreamController<KeyFrameInterpolation>();
  Sink<KeyFrameInterpolation> get changeInterpolation =>
      _interpolationController;

  KeyFrameManager(LinearAnimation animation, this.activeFile)
      : super(animation) {
    activeFile.addActionHandler(_onAction);
    activeFile.selection.addListener(_stageSelectionChanged);
    _selectionController.stream.listen(_selectKeyFrames);
    _interpolationController.stream.listen(_changeInterpolation);
  }

  void _stageSelectionChanged() => _clearSelection();

  bool _onAction(ShortcutAction action) {
    switch (action) {
      case ShortcutAction.delete:
        if (_selection.value.isNotEmpty) {
          _deleteKeyFrames(_selection.value);
          _clearSelection();
          return true;
        }
        break;
    }
    return false;
  }

  void _clearSelection() {
    var oldSelection = _selection.value;
    _selection.add(HashSet<KeyFrame>());
    _onChangeSelected(oldSelection);
  }

  void completeSelection() => _updateCommonInterpolation();

  void _updateCommonInterpolation() {
    var common = equalValue(
        _selection.value, (KeyFrame keyFrame) => keyFrame.interpolation);
    if (common != _interpolationType.value) {
      _interpolationType.add(common);
    }
  }

  void _changeInterpolation(KeyFrameInterpolation interpolation) {
    for (final keyFrame in _selection.value) {
      keyFrame.interpolation = interpolation;
    }
    animation.context.captureJournalEntry();
    _updateCommonInterpolation();
  }

  void _selectKeyFrames(HashSet<KeyFrame> keyFrames) {
    // if we want to multiselect, we need to add the existing selection to the
    // incoming keyframes.
    if (ShortcutAction.multiSelect.value) {
      keyFrames.addAll(_selection.value);
    }
    if (keyFrames.isEmpty || !_selection.value.containsAll(keyFrames)) {
      var oldSelection = _selection.value;
      _selection.add(keyFrames);
      _onChangeSelected(oldSelection);
    }
  }

  void _onChangeSelected(HashSet<KeyFrame> previous) {
    var selected = _selection.value;
    for (final keyFrame in previous) {
      keyFrame.removeListener(KeyFrameBase.interpolationTypePropertyKey,
          _keyframeInterpolationTypeChanged);
    }

    for (final keyFrame in selected) {
      keyFrame.addListener(KeyFrameBase.interpolationTypePropertyKey,
          _keyframeInterpolationTypeChanged);
    }
  }

  void _keyframeInterpolationTypeChanged(dynamic from, dynamic to) {
    debounce(_updateCommonInterpolation);
  }

  void _deleteKeyFrames(HashSet<KeyFrame> keyframes) {
    var core = animation.context;
    keyframes.forEach(core.remove);
    core.captureJournalEntry();
  }

  void dispose() {
    for (final keyFrame in _selection.value) {
      keyFrame.removeListener(KeyFrameBase.interpolationTypePropertyKey,
          _keyframeInterpolationTypeChanged);
    }
    activeFile.removeActionHandler(_onAction);
    activeFile.selection.removeListener(_stageSelectionChanged);
    _selection.close();
    _selectionController.close();
    _interpolationType.close();
    _interpolationController.close();
    cancelDebounce(_updateCommonInterpolation);
  }
}
