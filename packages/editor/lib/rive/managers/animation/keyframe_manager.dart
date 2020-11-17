import 'dart:async';
import 'dart:collection';

import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:rive_core/animation/cubic_interpolator.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rive_editor/rive/managers/animation/animation_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';
import 'package:utilities/list_equality.dart';
import 'package:rive_core/animation/interpolator.dart';
import 'package:meta/meta.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

class KeyFrameManager extends AnimationManager with RiveFileDelegate {
  final OpenFileContext activeFile;
  final _selection =
      BehaviorSubject<HashSet<KeyFrame>>.seeded(HashSet<KeyFrame>());
  ValueStream<HashSet<KeyFrame>> get selection => _selection;

  final _selectionController = StreamController<HashSet<KeyFrame>>();
  final _isSelectingController = StreamController<bool>();

  /// This is meant to be used by an operation that actively changes the
  /// selection as the operation progresses. Before starting a multi
  /// changeSelection operation set isSelecting to true and then set it back to
  /// false when complete.
  Sink<HashSet<KeyFrame>> get changeSelection => _selectionController;

  /// Add true when a selection operation begins and add false when it
  /// completes. This lets other systems query if there's an ongoing selection
  /// op and can allow them to opt out of their selection logic/grant priority
  /// to the system doing the selection op.
  Sink<bool> get isSelecting => _isSelectingController;

  final _commonInterpolation = BehaviorSubject<InterpolationViewModel>();
  ValueStream<InterpolationViewModel> get commonInterpolation =>
      _commonInterpolation;

  final _cubicController = StreamController<CubicInterpolationViewModel>();
  Sink<CubicInterpolationViewModel> get changeCubic => _cubicController;

  final _interpolationController = StreamController<KeyFrameInterpolation>();
  Sink<KeyFrameInterpolation> get changeInterpolation =>
      _interpolationController;

  KeyFrameManager(LinearAnimation animation, this.activeFile)
      : super(animation) {
    activeFile.core.addDelegate(this);
    activeFile.addActionHandler(_onAction);
    activeFile.selection.addListener(_stageSelectionChanged);

    _interpolationController.stream.listen(_changeInterpolation);
    _cubicController.stream.listen(_changeCubicInterpolation);
    _selectionController.stream.listen(_changeSelection);
    _isSelectingController.stream.listen(_changeIsSelecting);
    _updateCommonInterpolation();
  }

  @override
  void onObjectRemoved(Core object) {
    // When a keyframe is removed, schedule a pass to clean the selection when
    // the dirty cycle completes.
    if (object is KeyFrame) {
      activeFile.core.dirty(_cleanSelection);
    }
  }

  bool _clearOnStageSelection = true;
  bool _isChangingSelection = false;
  bool get isChangingSelection => _isChangingSelection;

  /// Check if any keyframes have been removed from core, this lets us clean up
  /// our selection in a self contained way and dispatch only one change in the
  /// stream even when multiple keyframes are deleted in a single action.
  void _cleanSelection() {
    // In case event comes in after we've closed.
    if (_selection.isClosed) {
      return;
    }
    var oldSelection = _selection.value;
    var selection = HashSet<KeyFrame>.from(_selection.value);

    bool changed = false;
    for (final keyframe in oldSelection) {
      if (!keyframe.isActive) {
        selection.remove(keyframe);
        changed = true;
      }
    }
    if (changed) {
      _changeSelectedKeyframes(selection);
    }
  }

  void _changeSelectedKeyframes(HashSet<KeyFrame> keyframes,
      {bool affectsStage = true}) {
    _selection.add(keyframes);
    if (affectsStage) {
      debounce(_syncStageWithKeyframeSelection);
    } else {
      cancelDebounce(_syncStageWithKeyframeSelection);
    }
  }

  /// Infer selected stage items from selected keyframes.
  void _syncStageWithKeyframeSelection() {
    // Gate changing the selection when the file reports a selection change. We
    // want to control the entire selection in this context.
    bool wasClearingOnStageSelection = _clearOnStageSelection;
    _clearOnStageSelection = false;

    var keyframes = _selection.value;
    var core = activeFile.core;
    Set<StageItem> toSelect = {};
    for (final frame in keyframes) {
      var component =
          core.resolve<Component>(frame.keyedProperty.keyedObject.objectId);
      if (component?.stageItem?.stage != null) {
        toSelect.add(component.stageItem);
      }
    }
    activeFile.selection.selectMultiple(toSelect);

    _clearOnStageSelection = wasClearingOnStageSelection;
  }

  void _stageSelectionChanged() {
    if (_clearOnStageSelection) {
      _clearSelection();
    }
  }

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
    _changeSelectedKeyframes(HashSet<KeyFrame>(), affectsStage: false);
    _onChangeSelected(oldSelection);
    _updateCommonInterpolation();
  }

  void _updateCommonInterpolation() {
    var common = equalValue(
        _selection.value, (KeyFrame keyFrame) => keyFrame.interpolation);
    Interpolator commonInterpolator;
    switch (common) {
      case KeyFrameInterpolation.linear:
      case KeyFrameInterpolation.hold:
        break;
      default:
        commonInterpolator = equalValue(
          _selection.value,
          (KeyFrame keyFrame) => keyFrame.interpolator,
          equalityCheck: (Interpolator a, Interpolator b) =>
              a?.equalParameters(b) ?? false,
        );
        // We were of the same type, but our parameters weren't equal, so we
        // effectively don't have a common editable interpolation type.
        if (commonInterpolator == null) {
          common = null;
        }
        break;
    }

    var viewModel = InterpolationViewModel(common, commonInterpolator);
    if (viewModel != _commonInterpolation.value) {
      _commonInterpolation.add(viewModel);
    }
  }

  void _changeCubicInterpolation(CubicInterpolationViewModel viewModel) {
    for (final keyFrame in _selection.value) {
      switch (keyFrame.interpolation) {
        case KeyFrameInterpolation.cubic:
          var interpolator = keyFrame.interpolator;
          if (interpolator is CubicInterpolator) {
            interpolator.x1 = viewModel.x1;
            interpolator.y1 = viewModel.y1;
            interpolator.x2 = viewModel.x2;
            interpolator.y2 = viewModel.y2;
          }
          break;
        default:
          break;
      }
    }
    _updateCommonInterpolation();
  }

  void _changeInterpolation(KeyFrameInterpolation interpolation) {
    var file = animation.context;
    for (final keyFrame in _selection.value) {
      keyFrame.interpolation = interpolation;
      switch (interpolation) {
        case KeyFrameInterpolation.cubic:
          var cubic = CubicInterpolator();
          // Add it before setting it so that it gets an id.
          file.addObject(cubic);
          keyFrame.interpolator = cubic;
          break;
        default:
          if (keyFrame.interpolator != null) {
            file.removeObject(keyFrame.interpolator as Core);
          }
          keyFrame.interpolator = null;
          break;
      }
    }

    file.captureJournalEntry();
    _updateCommonInterpolation();
  }

  void _changeIsSelecting(bool value) {
    _isChangingSelection = value;
    if(!value) {
      _updateCommonInterpolation();
    }
  }

  void _changeSelection(HashSet<KeyFrame> keyFrames) {
    _isChangingSelection = true;
    var oldSelection = _selection.value;

    // Selection should always have a valid set, even if requesting null
    // selection.
    _changeSelectedKeyframes(keyFrames != null
        ? HashSet<KeyFrame>.from(keyFrames)
        : HashSet<KeyFrame>());
    _onChangeSelected(oldSelection);
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
    keyframes.forEach(core.removeObject);
    core.captureJournalEntry();
  }

  void dispose() {
    for (final keyFrame in _selection.value) {
      keyFrame.removeListener(KeyFrameBase.interpolationTypePropertyKey,
          _keyframeInterpolationTypeChanged);
    }
    _cubicController.close();
    _selectionController.close();
    _isSelectingController.close();
    activeFile.core.removeDelegate(this);
    activeFile.removeActionHandler(_onAction);
    activeFile.selection.removeListener(_stageSelectionChanged);
    _selection.close();
    _interpolationController.close();
    _commonInterpolation.close();
    cancelDebounce(_updateCommonInterpolation);
    cancelDebounce(_syncStageWithKeyframeSelection);
  }
}

@immutable
class InterpolationViewModel {
  final KeyFrameInterpolation type;
  final Interpolator interpolator;

  const InterpolationViewModel(this.type, this.interpolator);
}

@immutable
class CubicInterpolationViewModel {
  final double x1, y1, x2, y2;
  const CubicInterpolationViewModel(
    this.x1,
    this.y1,
    this.x2,
    this.y2,
  );
}
