import 'package:flutter/material.dart';

/// A ShortcutAction that can be looked up by name (helpful for things like the
/// shortcuts modal which shows available shortcut bindings, and  may eventually
/// let you change/rebind some). The names are meant to be keys into a localized
/// dictionary later at some point. So at some points we'll have a json
/// dictionary:
///
/// {
///   "tool-artboard": "Artboard Tool",
///   "tool-auto": "Select Tool",
///   ...
/// }
class ShortcutAction {
  static const ShortcutAction artboardTool = ShortcutAction('tool-artboard');

  static const ShortcutAction autoTool = ShortcutAction('tool-auto');

  static const ShortcutAction boneTool = ShortcutAction('tool-bone');
  static const ShortcutAction cancel = ShortcutAction('cancel');
  static const ShortcutAction copy = ShortcutAction('copy');
  static const ShortcutAction cut = ShortcutAction('cut');

  /// Cycle through the currently hovered items (items below the cursor on the
  /// stage). Helps select things when they are heavily layered.
  static const ShortcutAction cycleHover = ShortcutAction('cycle-hover');

  static const ShortcutAction delete = ShortcutAction('delete');
  static const ShortcutAction deselect = ShortcutAction('deselect');
  static const ShortcutAction drawMeshTool = ShortcutAction('tool-mesh');
  static const ShortcutAction duplicate = ShortcutAction('duplicate');
  static const ShortcutAction find = ShortcutAction('find');
  static const ShortcutAction forceRevision = ShortcutAction('revision-force');
  static const ShortcutAction group = ShortcutAction('group');
  static const ShortcutAction groupSolo = ShortcutAction('group-solo');
  static const ShortcutAction ikTool = ShortcutAction('tool-ik');
  static const ShortcutAction moveSelectionPrevFrame =
      ShortcutAction('frame-move-prev');
  static const ShortcutAction moveSelectionNextFrame =
      ShortcutAction('frame-move-next');
  static const ShortcutAction moveSelectionPrev10Frames =
      ShortcutAction('frame-move-prev-10');
  static const ShortcutAction moveSelectionNext10Frames =
      ShortcutAction('frame-move-next-10');
  static HoldShortcutAction multiSelect = HoldShortcutAction('multi-select');
  static const ShortcutAction next10Frames = ShortcutAction('frame-next-10');
  static const ShortcutAction nextFrame = ShortcutAction('frame-next');
  static const ShortcutAction nextKeyFrame = ShortcutAction('frame-next-key');
  static const ShortcutAction nodeTool = ShortcutAction('tool-node');
  static HoldShortcutAction pan = HoldShortcutAction('pan');
  static const ShortcutAction paste = ShortcutAction('paste');

  static const ShortcutAction poseTool = ShortcutAction('tool-pose');
  static const ShortcutAction previous10Frames =
      ShortcutAction('frame-prev-10');
  static const ShortcutAction previousFrame = ShortcutAction('frame-prev');
  static const ShortcutAction previousKeyFrame =
      ShortcutAction('frame-prev-key');
  static const ShortcutAction redo = ShortcutAction('redo', repeats: true);
  static const ShortcutAction rotateTool = ShortcutAction('tool-rotate');

  static const ShortcutAction scaleTool = ShortcutAction('tool-scale');
  static const ShortcutAction selectAll = ShortcutAction('select-all');
  static const ShortcutAction selectChildrenTool =
      ShortcutAction('tool-select-children');
  static const ShortcutAction toggleShortcutsModal =
      ShortcutAction('show-shortcuts');
  static const ShortcutAction soloTool = ShortcutAction('tool-solo');
  static const ShortcutAction penTool = ShortcutAction('tool-pen');
  static const ShortcutAction rectangleTool = ShortcutAction('tool-rectangle');
  static const ShortcutAction ellipseTool = ShortcutAction('tool-ellipse');
  static const ShortcutAction timelineEnd = ShortcutAction('timeline-end');
  static const ShortcutAction timelineStart = ShortcutAction('timeline-start');
  static const ShortcutAction togglePlay = ShortcutAction('play');
  static const ShortcutAction translateTool = ShortcutAction('tool-translate');
  static const ShortcutAction undo = ShortcutAction('undo', repeats: true);
  static const ShortcutAction paintWeightTool = ShortcutAction('tool-weight');
  static const ShortcutAction zoom100 = ShortcutAction('zoom-100');
  static const ShortcutAction zoomFit = ShortcutAction('zoom-fit');
  static const ShortcutAction zoomIn = ShortcutAction('zoom-in', repeats: true);
  static const ShortcutAction zoomOut =
      ShortcutAction('zoom-out', repeats: true);
  static const ShortcutAction item1 = ShortcutAction('item-1');
  static const ShortcutAction item10 = ShortcutAction('item-10');

  static const ShortcutAction item2 = ShortcutAction('item-2');
  static const ShortcutAction item3 = ShortcutAction('item-3');
  static const ShortcutAction item4 = ShortcutAction('item-4');
  static const ShortcutAction item5 = ShortcutAction('item-5');
  static const ShortcutAction item6 = ShortcutAction('item-6');
  static const ShortcutAction item7 = ShortcutAction('item-7');
  static const ShortcutAction item8 = ShortcutAction('item-8');
  static const ShortcutAction item9 = ShortcutAction('item-9');
  static const ShortcutAction keySelected = ShortcutAction('key-selected');
  static const ShortcutAction keySelectedLength =
      ShortcutAction('key-bone-length');
  static const ShortcutAction keySelectedRotation =
      ShortcutAction('key-rotation');
  static const ShortcutAction keySelectedScale = ShortcutAction('key-scale');
  static const ShortcutAction keySelectedTranslation =
      ShortcutAction('key-translation');
  static const ShortcutAction nextItem = ShortcutAction('next');
  static const ShortcutAction previousItem = ShortcutAction('prev');

  static const ShortcutAction bumpDown = ShortcutAction('bump-down');
  static const ShortcutAction bumpLeft = ShortcutAction('bump-left');
  static const ShortcutAction bumpRight = ShortcutAction('bump-right');
  static const ShortcutAction bumpUp = ShortcutAction('bump-up');

  static const ShortcutAction nudgeDown =
      ShortcutAction('nudge-down', repeats: true);
  static const ShortcutAction nudgeLeft =
      ShortcutAction('nudge-left', repeats: true);
  static const ShortcutAction nudgeRight =
      ShortcutAction('nudge-right', repeats: true);
  static const ShortcutAction nudgeUp =
      ShortcutAction('nudge-up', repeats: true);
  static const ShortcutAction megaNudgeDown =
      ShortcutAction('mega-nudge-down', repeats: true);
  static const ShortcutAction megaNudgeLeft =
      ShortcutAction('mega-nudge-left', repeats: true);
  static const ShortcutAction megaNudgeRight =
      ShortcutAction('mega-nudge-right', repeats: true);
  static const ShortcutAction megaNudgeUp =
      ShortcutAction('mega-nudge-up', repeats: true);

  static const ShortcutAction resetRulers = ShortcutAction('reset-rulers');
  static const ShortcutAction toggleRulers = ShortcutAction('rulers');

  static const ShortcutAction allSelectionFilter =
      ShortcutAction('selection-filter-all');
  static const ShortcutAction boneSelectionFilter =
      ShortcutAction('selection-filter-bone');

  static const ShortcutAction imageSelectionFilter =
      ShortcutAction('selection-filter-bone');
  static const ShortcutAction nextSelectionFilter =
      ShortcutAction('selection-filter-next');
  static const ShortcutAction previousSelectionFilter =
      ShortcutAction('selection-filter-prev');
  static const ShortcutAction vertexSelectionFilter =
      ShortcutAction('selection-filter-vertex');
  static const ShortcutAction hoverShowInHierarchy =
      ShortcutAction('reveal-in-hierarchy');
  static const ShortcutAction switchMode = ShortcutAction('switch-mode');

  static const ShortcutAction bringForward = ShortcutAction('bring-forward');
  static const ShortcutAction sendBackward = ShortcutAction('send-backward');

  static const ShortcutAction sendToBack = ShortcutAction('send-to-back');
  static const ShortcutAction sendToFront = ShortcutAction('send-to-front');
  static const ShortcutAction pickParent = ShortcutAction('pick-parent');
  static const ShortcutAction toggleEditMode = ShortcutAction('edit-mode');

  static ToggleShortcutAction freezeToggle = ToggleShortcutAction('freeze');

  static HoldShortcutAction disableSnapping =
      HoldShortcutAction('disable-snapping');

  static HoldShortcutAction mouseWheelZoom =
      HoldShortcutAction('mouse-wheel-zoom');
  static HoldShortcutAction deepClick = HoldShortcutAction('deep-click');
  static HoldShortcutAction symmetricDraw =
      HoldShortcutAction('symmetric-draw');
  static const ShortcutAction confirm = ShortcutAction('action');

  static const ShortcutAction navigateTreeUp = ShortcutAction('nav-tree-up');
  static const ShortcutAction navigateTreeDown =
      ShortcutAction('nav-tree-down');
  static const ShortcutAction navigateTreeLeft =
      ShortcutAction('nav-tree-left');
  static const ShortcutAction navigateTreeRight =
      ShortcutAction('nav-tree-right');

  // UI related
  static const ShortcutAction left =
      ShortcutAction('action-left', repeats: true);
  static const ShortcutAction right =
      ShortcutAction('action-right', repeats: true);
  static const ShortcutAction up = ShortcutAction('action-up', repeats: true);
  static const ShortcutAction down =
      ShortcutAction('action-down', repeats: true);

  static const ShortcutAction closeTab = ShortcutAction('close-tab');
  static ToggleShortcutAction showActions =
      ToggleShortcutAction('show-actions');

  final String name;
  final bool repeats;
  const ShortcutAction(this.name, {this.repeats = false});
}

/// A ShortcutAction that somehow mutates its value when it is pressed or
/// released.
abstract class StatefulShortcutAction<T> extends ShortcutAction
    with ChangeNotifier {
  T _value;
  StatefulShortcutAction(String name, T defaultValue, {bool repeats = true})
      : _value = defaultValue,
        super(name, repeats: repeats);
  T get value => _value;

  void _changeValue(T change) {
    if (change != _value) {
      _value = change;
      notifyListeners();
    }
  }

  void onPress();
  void onRelease();
}

/// A ShortcutAction with a backing boolean value turned on/off when the key
/// is pressed/released.
class HoldShortcutAction extends StatefulShortcutAction<bool> {
  HoldShortcutAction(String name) : super(name, false, repeats: false);

  @override
  void onPress() => _changeValue(true);

  @override
  void onRelease() => _changeValue(false);
}

/// A ShortcutAction with a backing boolean value toggled on/off when the key
/// is pressed.
class ToggleShortcutAction extends StatefulShortcutAction<bool> {
  ToggleShortcutAction(String name) : super(name, false);

  void toggle() {
    _changeValue(!_value);
  }

  @override
  void onPress() => toggle();

  @override
  void onRelease() {
    // intentionally empty, value only toggled on press.
  }
}
