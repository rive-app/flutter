import 'package:core/id.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/draw_target.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/src/generated/draw_rules_base.dart';
import 'package:rive_core/transform_component.dart';
export 'package:rive_core/src/generated/draw_rules_base.dart';

class DrawRules extends DrawRulesBase {
  // -> editor-only
  DrawRules parentRules;
  // <- editor-only
  final Set<DrawTarget> _targets = {};
  Set<DrawTarget> get targets => _targets;

  DrawTarget _activeTarget;
  DrawTarget get activeTarget => _activeTarget;
  set activeTarget(DrawTarget value) => drawTargetId = value?.id;

  @override
  void drawTargetIdChanged(Id from, Id to) {
    _activeTarget = context?.resolve(to);
    artboard?.markDrawOrderDirty();
    // -> editor-only
    drawRulesChanged?.notify();
    // <- editor-only
  }

  @override
  void onAddedDirty() {
    if (drawTargetId != null) {
      _activeTarget = context?.resolve(drawTargetId);
    }
    else {
      _activeTarget = null;
    }
  }

  @override
  void update(int dirt) {
    // TODO: implement update
  }

  @override
  void childAdded(Component child) {
    super.childAdded(child);
    switch (child.coreType) {
      case DrawTargetBase.typeKey:
        _targets.add(child as DrawTarget);
        artboard?.markNaturalDrawOrderDirty();
        // -> editor-only
        context?.dirty(_updateDrawRules);
        // <- editor-only
        break;
    }
  }

  @override
  void childRemoved(Component child) {
    super.childRemoved(child);
    switch (child.coreType) {
      case DrawTargetBase.typeKey:
        _targets.remove(child as DrawTarget);
        artboard?.markNaturalDrawOrderDirty();
        if (_targets.isEmpty) {
          remove();
        }
        // -> editor-only
        context?.dirty(_updateDrawRules);
        // <- editor-only
        break;
    }
  }

  // -> editor-only
  void _updateDrawRules() {
    // If we've been removed from core, early out.
    if (!isActive) {
      return;
    }
    drawRulesChanged?.notify();
    // Make sure the active target is still in our list.
    if (!_targets.contains(_activeTarget)) {
      drawTargetId = emptyId;
    }
  }

  Event get drawRulesChanged =>
      (parent as TransformComponent)?.drawRulesChanged;

  @override
  bool validate() =>
      super.validate() && _targets.isNotEmpty && parent is TransformComponent;
  // <- editor-only
}
