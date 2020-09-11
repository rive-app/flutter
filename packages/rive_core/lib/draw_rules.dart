import 'package:core/id.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/draw_target.dart';
import 'package:rive_core/src/generated/draw_rules_base.dart';
export 'package:rive_core/src/generated/draw_rules_base.dart';

class DrawRules extends DrawRulesBase {
  final Set<DrawTarget> _targets = {};
  Set<DrawTarget> get targets => _targets;

  @override
  void drawTargetIdChanged(Id from, Id to) {
    // TODO: implement drawTargetIdChanged
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
        break;
    }
  }
}
