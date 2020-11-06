import 'shortcut_actions.dart';
import 'shortcut_key_binding.dart';
import 'shortcut_keys.dart';

/// Default key binding for Rive.
final ShortcutKeyBinding defaultKeyBinding = ShortcutKeyBinding(
  [
    Shortcut(ShortcutAction.deselect, {ShortcutKey.systemCmd, ShortcutKey.d}),
    Shortcut(ShortcutAction.zoomIn, {ShortcutKey.equal}),
    Shortcut(ShortcutAction.zoomOut, {ShortcutKey.minus}),
    Shortcut(ShortcutAction.zoomIn, {ShortcutKey.systemCmd, ShortcutKey.equal}),
    Shortcut(
        ShortcutAction.zoomOut, {ShortcutKey.systemCmd, ShortcutKey.minus}),
    Shortcut(ShortcutAction.zoom100, {ShortcutKey.systemCmd, ShortcutKey.zero}),
    Shortcut(ShortcutAction.zoomFit, {ShortcutKey.f}),
    Shortcut(ShortcutAction.showActions,
        {ShortcutKey.alt, ShortcutKey.shift, ShortcutKey.a}),
    Shortcut(ShortcutAction.cycleHover, {ShortcutKey.alt}),
    Shortcut(ShortcutAction.multiSelect, {ShortcutKey.shift}),
    Shortcut(ShortcutAction.togglePlay, {ShortcutKey.space}),
    Shortcut(ShortcutAction.mouseWheelZoom, {ShortcutKey.systemCmd}),
    Shortcut(ShortcutAction.disableSnapping, {ShortcutKey.systemCmd}),
    Shortcut(ShortcutAction.deepClick, {ShortcutKey.systemCmd}),
    Shortcut(ShortcutAction.symmetricDraw, {ShortcutKey.shift}),
    Shortcut(ShortcutAction.pan, {ShortcutKey.space}),
    Shortcut(ShortcutAction.toggleEditMode, {ShortcutKey.enter}),

    Shortcut(ShortcutAction.left, {ShortcutKey.left}),
    Shortcut(ShortcutAction.right, {ShortcutKey.right}),
    Shortcut(ShortcutAction.up, {ShortcutKey.up}),
    Shortcut(ShortcutAction.down, {ShortcutKey.down}),
    Shortcut(ShortcutAction.nudgeLeft, {ShortcutKey.left}),
    Shortcut(ShortcutAction.nudgeRight, {ShortcutKey.right}),
    Shortcut(ShortcutAction.nudgeUp, {ShortcutKey.up}),
    Shortcut(ShortcutAction.nudgeDown, {ShortcutKey.down}),
    Shortcut(
      ShortcutAction.megaNudgeLeft,
      {ShortcutKey.shift, ShortcutKey.left},
    ),
    Shortcut(
      ShortcutAction.megaNudgeRight,
      {ShortcutKey.shift, ShortcutKey.right},
    ),
    Shortcut(
      ShortcutAction.megaNudgeUp,
      {ShortcutKey.shift, ShortcutKey.up},
    ),
    Shortcut(
      ShortcutAction.megaNudgeDown,
      {ShortcutKey.shift, ShortcutKey.down},
    ),

    Shortcut(ShortcutAction.confirm, {ShortcutKey.enter}),
    Shortcut(
      ShortcutAction.copy,
      {
        ShortcutKey.systemCmd,
        ShortcutKey.c,
      },
    ),
    Shortcut(
      ShortcutAction.paste,
      {
        ShortcutKey.systemCmd,
        ShortcutKey.v,
      },
    ),
    Shortcut(
      ShortcutAction.cut,
      {
        ShortcutKey.systemCmd,
        ShortcutKey.x,
      },
    ),
    Shortcut(
      ShortcutAction.undo,
      {
        ShortcutKey.systemCmd,
        ShortcutKey.z,
      },
    ),
    Shortcut(
      ShortcutAction.redo,
      {
        ShortcutKey.shift,
        ShortcutKey.systemCmd,
        ShortcutKey.z,
      },
    ),
    Shortcut(
      ShortcutAction.pickParent,
      {
        ShortcutKey.shift,
        ShortcutKey.c,
      },
    ),
    Shortcut(
      ShortcutAction.switchMode,
      {
        ShortcutKey.tab,
      },
    ),
    Shortcut(
      ShortcutAction.hoverShowInHierarchy,
      {
        ShortcutKey.h,
      },
    ),
    Shortcut(
      ShortcutAction.nextSelectionFilter,
      {
        ShortcutKey.v,
      },
    ),
    Shortcut(
      ShortcutAction.previousSelectionFilter,
      {
        ShortcutKey.shift,
        ShortcutKey.v,
      },
    ),
    Shortcut(
      ShortcutAction.previousKeyFrame,
      {
        ShortcutKey.comma,
      },
    ),
    Shortcut(
      ShortcutAction.nextKeyFrame,
      {
        ShortcutKey.period,
      },
    ),
    Shortcut(
      ShortcutAction.keySelected,
      {
        ShortcutKey.k,
      },
    ),
    Shortcut(
      ShortcutAction.delete,
      {
        ShortcutKey.backspace,
      },
    ),
    Shortcut(
      ShortcutAction.delete,
      {
        ShortcutKey.delete,
      },
    ),
    Shortcut(
      ShortcutAction.cancel,
      {
        ShortcutKey.esc,
      },
    ),
    Shortcut(
      ShortcutAction.rotateTool,
      {
        ShortcutKey.r,
      },
    ),
    // Shortcut(
    //   ShortcutAction.scaleTool,
    //   {
    //     ShortcutKey.s,
    //   },
    // ),
    Shortcut(
      ShortcutAction.poseTool,
      {
        ShortcutKey.x,
      },
    ),
    Shortcut(
      ShortcutAction.autoTool,
      {
        ShortcutKey.v,
      },
    ),
    Shortcut(
      ShortcutAction.translateTool,
      {
        ShortcutKey.t,
      },
    ),
    Shortcut(
      ShortcutAction.keySelectedTranslation,
      {
        ShortcutKey.shift,
        ShortcutKey.t,
      },
    ),
    Shortcut(
      ShortcutAction.selectChildrenTool,
      {
        ShortcutKey.c,
      },
    ),
    // Shortcut(
    //   ShortcutAction.paintWeightTool,
    //   {
    //     ShortcutKey.w,
    //   },
    // ),
    Shortcut(
      ShortcutAction.ellipseTool,
      {
        ShortcutKey.o,
      },
    ),
    Shortcut(
      ShortcutAction.rectangleTool,
      {
        ShortcutKey.r,
      },
    ),
    Shortcut(
      ShortcutAction.penTool,
      {
        ShortcutKey.p,
      },
    ),
    Shortcut(
      ShortcutAction.artboardTool,
      {
        ShortcutKey.m,
      },
    ),
    Shortcut(
      ShortcutAction.boneTool,
      {
        ShortcutKey.b,
      },
    ),
    Shortcut(
      ShortcutAction.nodeTool,
      {
        ShortcutKey.g,
      },
    ),
    Shortcut(
      ShortcutAction.soloTool,
      {
        ShortcutKey.y,
      },
    ),
    Shortcut(
      ShortcutAction.freezeImagesToggle,
      {
        ShortcutKey.k,
      },
    ),
    Shortcut(
      ShortcutAction.freezeJointsToggle,
      {
        ShortcutKey.j,
      },
    ),
    Shortcut(
      ShortcutAction.resetRulers,
      {
        ShortcutKey.shift,
        ShortcutKey.semiColon,
      },
    ),
    Shortcut(
      ShortcutAction.toggleRulers,
      {
        ShortcutKey.semiColon,
      },
    ),
    Shortcut(
      ShortcutAction.closeTab,
      {
        ShortcutKey.systemCmd,
        ShortcutKey.w,
      },
    ),
    Shortcut(ShortcutAction.navigateTreeUp, {ShortcutKey.w}),
    Shortcut(ShortcutAction.navigateTreeLeft, {ShortcutKey.a}),
    Shortcut(ShortcutAction.navigateTreeDown, {ShortcutKey.s}),
    Shortcut(ShortcutAction.navigateTreeRight, {ShortcutKey.d}),
  ],
);
