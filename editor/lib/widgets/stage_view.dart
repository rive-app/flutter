import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import '../rive/rive.dart';

/// Draws a path with custom paint and a nuge property.
class StageView extends LeafRenderObjectWidget {
  /// The Rive context.
  final Rive rive;

  const StageView(this.rive);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _StageViewRenderObject()..rive = rive;
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _StageViewRenderObject renderObject) {
    renderObject..rive = rive;
  }

  @override
  void didUnmountRenderObject(covariant _StageViewRenderObject renderObject) {
    renderObject.dispose();
  }
}

class _StageViewRenderObject extends RenderBox implements StageDelegate {
  Rive _rive;

  Rive get rive => _rive;
  set rive(Rive value) {
    if (_rive == value) {
      return;
    }
    _rive = value;
    _rive.stage.delegate(this);
    markNeedsPaint();
  }

  @override
  bool get sizedByParent => true;

  @override
  void performResize() {
    size = constraints.biggest;
  }

  @override
  void performLayout() {
    _rive.stage.setViewport(size.width, size.height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (isPlaying) {
      // Paint again
      if (_frameCallbackID != null) {
        SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallbackID);
      }
      _frameCallbackID =
          SchedulerBinding.instance.scheduleFrameCallback(_beginFrame);
    }

    rive.stage.paint(context, offset, size);
  }

  int _frameCallbackID;
  double _lastFrameTime = 0.0;

  bool get isPlaying => _rive.stage.shouldAdvance;

  void _beginFrame(Duration timestamp) {
    _frameCallbackID = null;
    final double t =
        timestamp.inMicroseconds / Duration.microsecondsPerMillisecond / 1000.0;
    double elapsedSeconds = _lastFrameTime == 0.0 ? 0.0 : t - _lastFrameTime;
    _lastFrameTime = t;

    // advance(elapsedSeconds);
    rive.stage.advance(elapsedSeconds);
    if (!isPlaying) {
      _lastFrameTime = 0.0;
    }
    markNeedsPaint();
  }

  void updatePlayState() {
    if (isPlaying && attached) {
      markNeedsPaint();
    } else {
      _lastFrameTime = 0;
      if (_frameCallbackID != null) {
        SchedulerBinding.instance.cancelFrameCallbackWithId(_frameCallbackID);
      }
    }
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    updatePlayState();
  }

  void dispose() {
    updatePlayState();
    rive?.stage?.clearDelegate(this);
    rive = null;
  }

  @override
  void stageNeedsAdvance() {
    updatePlayState();
  }
}
