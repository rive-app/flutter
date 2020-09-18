import 'dart:async';
import 'dart:collection';

import 'package:core/core.dart';
import 'package:core/debounce.dart';
import 'package:rive_core/animation/cubic_interpolator.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/linear_animation.dart';
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

class KeyFrameManager extends AnimationManager with RiveFileDelegate {
  final OpenFileContext activeFile;
  final _selection =
      BehaviorSubject<HashSet<KeyFrame>>.seeded(HashSet<KeyFrame>());
  ValueStream<HashSet<KeyFrame>> get selection => _selection;

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
      _selection.add(selection);
    }
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
    _updateCommonInterpolation();
  }

  void completeSelection() => _updateCommonInterpolation();

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

  void changeSelection(HashSet<KeyFrame> keyFrames) {
    var oldSelection = _selection.value;

    // Selection should always have a valid set, even if requesting null
    // selection.
    _selection.add(keyFrames != null
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
    activeFile.core.removeDelegate(this);
    activeFile.removeActionHandler(_onAction);
    activeFile.selection.removeListener(_stageSelectionChanged);
    _selection.close();
    _interpolationController.close();
    _commonInterpolation.close();
    cancelDebounce(_updateCommonInterpolation);
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
