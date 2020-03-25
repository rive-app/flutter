import 'dart:async';

import 'package:cursor/cursor_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_editor/rive/draw_order_tree_controller.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/shortcuts/default_key_binding.dart';
import 'package:rive_editor/widgets/changelog.dart';
import 'package:rive_editor/widgets/disconnected_screen.dart';
import 'package:rive_editor/widgets/draw_order.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/toolbar/connected_users.dart';
import 'package:rive_editor/widgets/toolbar/create_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/design_animate_toggle.dart';
import 'package:rive_editor/widgets/toolbar/hamburger_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/share_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/transform_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/visibility_toolbar.dart';
import 'package:window_utils/window_utils.dart';
import 'package:core/error_logger.dart';

import 'constants.dart';
import 'rive/hierarchy_tree_controller.dart';
import 'rive/rive.dart';
import 'rive/stage/stage.dart';
import 'widgets/catastrophe.dart';
import 'widgets/files_view/screen.dart';
import 'widgets/hierarchy.dart';
import 'widgets/inspector/inspector_panel.dart';
import 'widgets/login.dart';
import 'widgets/resize_panel.dart';
import 'widgets/stage_view.dart';
import 'widgets/tab_bar/rive_tab_bar.dart';
import 'widgets/toolbar/connected_users.dart';
import 'widgets/toolbar/design_animate_toggle.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorLogger.instance.onError(details.exception, details.stack);
  };

  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) {
      WindowUtils.hideTitleBar();
      WindowUtils.setSize(kDefaultWIndowSize);
    },
  );

  final iconCache = RiveIconCache(rootBundle);
  final rive = Rive(
    iconCache: iconCache,
    focusNode: FocusNode(canRequestFocus: true, skipTraversal: true),
  );

  if (await rive.initialize() != RiveState.catastrophe) {
    // this is just for the prototype...
    // await rive.open('100/100');
  }

  // Runs the app in a custom [Zone] (i.e. an execution context).
  // Provides a convenient way to capture all errors, so they can be reported
  // to our logger service.
  runZoned(
    () => runApp(
      RiveEditorApp(
        rive: rive,
        iconCache: iconCache,
      ),
    ),
    onError: (Object error, StackTrace stackTrace) {
      try {
        ErrorLogger.instance.onError(error, stackTrace);
      } on Exception catch (e) {
        debugPrint('Failed to report: $e');
        debugPrint('Error was: $error, $stackTrace');
      }
    },
  );
}

// Testing context menu items.
const double resizeEdgeSize = 10;

class RiveEditorApp extends StatelessWidget {
  final Rive rive;
  final RiveIconCache iconCache;

  const RiveEditorApp({
    Key key,
    this.rive,
    this.iconCache,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RiveTheme(
      child: ShortcutBindings(
        child: RiveContext(
          rive: rive,
          child: TipRoot(
            context: TipContext(),
            child: IconCache(
              cache: iconCache,
              child: Builder(
                builder: (context) => CursorView(
                  onPointerDown: (details) {
                    rive.focusNode.requestFocus();
                  },
                  child: MaterialApp(
                    debugShowCheckedModeBanner: false,
                    theme: ThemeData.light(),
                    home: DefaultTextStyle(
                      style: RiveTheme.of(context).textStyles.basic,
                      child: Container(
                        child: Scaffold(
                          body: RawKeyboardListener(
                            onKey: (event) {
                              final focusScope = FocusScope.of(context);
                              var primary = FocusManager.instance.primaryFocus;
                              rive.onKeyEvent(
                                  defaultKeyBinding,
                                  event,
                                  primary != rive.focusNode &&
                                      focusScope.nearestScope != primary);
                            },
                            child: ValueListenableBuilder<RiveState>(
                              valueListenable: rive.state,
                              builder: (context, state, _) {
                                switch (state) {
                                  case RiveState.login:
                                    return Login();

                                  case RiveState.editor:
                                    return Editor();

                                  case RiveState.disconnected:
                                    return DisconnectedScreen();
                                    break;

                                  case RiveState.catastrophe:
                                  default:
                                    return Catastrophe();
                                }
                              },
                            ),
                            focusNode: rive.focusNode,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Testing context menu items.
class Editor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var rive = RiveContext.of(context);
    return Column(
      children: [
        Container(
          height: 39,
          color: RiveTheme.of(context).colors.panelBackgroundDarkGrey,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(
                      child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (_) {
                            WindowUtils.startDrag();
                          }),
                    ),
                    ValueListenableBuilder<List<RiveTabItem>>(
                      valueListenable: rive.tabs,
                      builder: (context, tabs, child) =>
                          ValueListenableBuilder<RiveTabItem>(
                        valueListenable: rive.selectedTab,
                        builder: (context, selectedTab, child) => RiveTabBar(
                          offset: 95,
                          tabs: tabs,
                          selected: selectedTab,
                          select: rive.openTab,
                          close: rive.closeTab,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              FlatButton(
                child: const Text(
                  'Force Reconnect',
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  rive.forceReconnect();
                },
              )
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<List<RiveTabItem>>(
            valueListenable: rive.tabs,
            builder: (context, tabs, child) =>
                ValueListenableBuilder<RiveTabItem>(
              valueListenable: rive.selectedTab,
              builder: (context, tab, child) =>
                  _buildBody(context, tabs.indexOf(tab)),
            ),
          ),
        )
      ],
    );
  }

  Widget _buildBody(BuildContext context, int index) {
    switch (index) {
      case 0:
        return const FilesView();
      case 1:
        return const ChangeLog();
      default:
        return _buildEditor(context);
    }
  }

  Widget _buildEditor(BuildContext context) {
    final rive = RiveContext.of(context);
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(6),
          height: 42,
          color: const Color.fromRGBO(60, 60, 60, 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              HamburgerPopupButton(),
              TransformPopupButton(),
              CreatePopupButton(),
              SharePopupButton(),
              const Spacer(),
              ConnectedUsers(rive: rive),
              VisibilityPopupButton(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: DesignAnimateToggle(),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              HierarchyPanel(),
              const Expanded(
                child: StagePanel(),
              ),
              const ResizePanel(
                hitSize: resizeEdgeSize,
                direction: ResizeDirection.horizontal,
                side: ResizeSide.start,
                min: 235,
                max: 500,
                child: InspectorPanel(),
              ),
              /*Expanded(
                child: Column(
                  children: [
                    ResizePanel(
                      hitSize: resizeEdgeSize,
                      direction: ResizeDirection.vertical,
                      side: ResizeSide.end,
                      min: 100,
                      max: 500,
                      child: Container(
                        color: Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                    ),
                    Expanded(
                      child: StagePanel(),
                    ),
                    ResizePanel(
                      hitSize: resizeEdgeSize,
                      direction: ResizeDirection.vertical,
                      side: ResizeSide.start,
                      min: 100,
                      max: 500,
                      child: Container(
                        color: Color.fromRGBO(40, 40, 40, 1.0),
                      ),
                    ),
                  ],
                ),
              ),
              ResizePanel(
                hitSize: resizeEdgeSize,
                direction: ResizeDirection.horizontal,
                side: ResizeSide.start,
                min: 300,
                max: 500,
                child: Container(
                  color: Color.fromRGBO(50, 50, 50, 1.0),
                ),
              ),*/
            ],
          ),
        ),
      ],
    );
  }
}

/// Left hand panel contains the hierarchy and draw order widgets
class HierarchyPanel extends StatefulWidget {
  @override
  _HierarchyPanelState createState() => _HierarchyPanelState();
}

class _HierarchyPanelState extends State<HierarchyPanel> {
  bool hierarchySelected = true;
  bool hierarchyHovered = false;
  bool drawOrderHovered = false;

  @override
  Widget build(BuildContext context) {
    final rive = RiveContext.of(context);
    return ResizePanel(
      hitSize: resizeEdgeSize,
      direction: ResizeDirection.horizontal,
      side: ResizeSide.end,
      min: 300,
      max: 500,
      child: Container(
        color: RiveTheme.of(context).colors.panelBackgroundDarkGrey,
        child: Column(
          children: <Widget>[
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 20),
                child: MouseRegion(
                  onEnter: (_) => setState(() => hierarchyHovered = true),
                  onExit: (_) => setState(() => hierarchyHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => hierarchySelected = true);
                    },
                    child: Text('HIERARCHY',
                        style: hierarchySelected
                            ? RiveTheme.of(context)
                                .textStyles
                                .hierarchyTabActive
                            : hierarchyHovered
                                ? RiveTheme.of(context)
                                    .textStyles
                                    .hierarchyTabHovered
                                : RiveTheme.of(context)
                                    .textStyles
                                    .hierarchyTabInactive),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 20),
                child: MouseRegion(
                  onEnter: (_) => setState(() => drawOrderHovered = true),
                  onExit: (_) => setState(() => drawOrderHovered = false),
                  child: GestureDetector(
                    onTap: () => setState(() => hierarchySelected = false),
                    child: Text('DRAW ORDER',
                        style: hierarchySelected
                            ? drawOrderHovered
                                ? RiveTheme.of(context)
                                    .textStyles
                                    .hierarchyTabHovered
                                : RiveTheme.of(context)
                                    .textStyles
                                    .hierarchyTabInactive
                            : RiveTheme.of(context)
                                .textStyles
                                .hierarchyTabActive),
                  ),
                ),
              ),
            ]),
            if (hierarchySelected)
              Expanded(
                child: ValueListenableBuilder<HierarchyTreeController>(
                  valueListenable: rive.treeController,
                  builder: (context, controller, _) =>
                      HierarchyTreeView(controller: controller),
                ),
              ),
            if (!hierarchySelected)
              Expanded(
                // child: DrawOrder(),
                child: ValueListenableBuilder<DrawOrderTreeController>(
                  valueListenable: rive.drawOrderTreeController,
                  builder: (context, controller, _) =>
                      DrawOrderTreeView(controller: controller),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The central stage panel, where drawing/composing takes place
class StagePanel extends StatelessWidget {
  const StagePanel({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rive = RiveContext.of(context);
    return Container(
      color: RiveTheme.of(context).colors.stageBackground,
      child: ValueListenableBuilder<Stage>(
        valueListenable: rive.stage,
        builder: (context, stage, _) => Stack(
          children: [
            Positioned.fill(
              child: stage == null
                  ? Container()
                  : StageView(
                      rive: rive,
                      stage: stage,
                    ),
            ),
            Positioned(
              left: resizeEdgeSize,
              top: resizeEdgeSize,
              bottom: resizeEdgeSize,
              right: resizeEdgeSize,
              child: stage == null
                  ? Container()
                  : MouseRegion(
                      opaque: true,
                      onExit: (details) {
                        RenderBox getBox =
                            context.findRenderObject() as RenderBox;
                        var local = getBox.globalToLocal(details.position);
                        stage.mouseExit(details.buttons, local.dx, local.dy);
                      },
                      onHover: (details) {
                        RenderBox getBox =
                            context.findRenderObject() as RenderBox;
                        var local = getBox.globalToLocal(details.position);
                        stage.mouseMove(details.buttons, local.dx, local.dy);
                        // print('MOVE $local');
                      },
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerSignal: (details) {
                          if (details is PointerScrollEvent) {
                            RenderBox getBox =
                                context.findRenderObject() as RenderBox;
                            var local = getBox.globalToLocal(details.position);
                            stage.mouseWheel(local.dx, local.dy,
                                details.scrollDelta.dx, details.scrollDelta.dy);
                          }
                        },
                        onPointerDown: (details) {
                          RenderBox getBox =
                              context.findRenderObject() as RenderBox;
                          var local = getBox.globalToLocal(details.position);
                          stage.mouseDown(details.buttons, local.dx, local.dy);
                          rive.startDragOperation();
                        },
                        onPointerUp: (details) {
                          RenderBox getBox =
                              context.findRenderObject() as RenderBox;
                          var local = getBox.globalToLocal(details.position);
                          stage.mouseUp(details.buttons, local.dx, local.dy);
                          rive.endDragOperation();
                        },
                        onPointerMove: (details) {
                          RenderBox getBox =
                              context.findRenderObject() as RenderBox;
                          var local = getBox.globalToLocal(details.position);
                          stage.mouseDrag(details.buttons, local.dx, local.dy);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
