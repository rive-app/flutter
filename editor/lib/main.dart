import 'package:cursor/cursor_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_core/container_component.dart';
import 'package:rive_core/node.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/rive/shortcuts/default_key_binding.dart';
import 'package:rive_editor/widgets/disconnected_screen.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/toolbar/create_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/hamburger_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/transform_popup_button.dart';
import 'package:window_utils/window_utils.dart';

import 'rive/hierarchy_tree_controller.dart';
import 'rive/rive.dart';
import 'rive/stage/items/stage_artboard.dart';
import 'rive/stage/stage.dart';
import 'rive/stage/stage_item.dart';
import 'widgets/catastrophe.dart';
import 'widgets/files_view/screen.dart';
import 'widgets/hierarchy.dart';
import 'widgets/inspector/property_dual.dart';
import 'widgets/listenable_builder.dart';
import 'widgets/login.dart';

import 'widgets/popup/popup.dart';
import 'widgets/resize_panel.dart';
import 'widgets/stage_view.dart';
import 'widgets/tab_bar/rive_tab_bar.dart';
import 'widgets/theme.dart';
import 'widgets/toolbar/connected_users.dart';
import 'widgets/toolbar/design_animate_toggle.dart';
import 'widgets/toolbar/scale_dropdown.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => WindowUtils.hideTitleBar(),
  );

  var rive = Rive();
  if (await rive.initialize() != RiveState.catastrophe) {
    // this is just for the prototype...
    // await rive.open('100/100');
  }
  runApp(
    RiveEditorApp(
      rive: rive,
      focusNode: FocusNode(),
    ),
  );
}

// Testing context menu items.
const double resizeEdgeSize = 10;

// Hack
List<PopupContextItem<Rive>> contextItems = [
  PopupContextItem(
    'Artboard',
    select: (Rive rive) {
      var artboard = Artboard()
        ..name = 'New Artboard'
        ..x = 0
        ..y = 0
        ..width = 200
        ..height = 100;
      rive.file.value.add(artboard);
      rive.file.value.captureJournalEntry();
    },
  ),
  PopupContextItem(
    'Node',
    select: (rive) {
      if (rive.selection.isEmpty) {
        print('No selection to parent Node to.');
        return;
      }

      var selection = rive.selection.first;
      if (selection is StageItem && selection.component is ContainerComponent) {
        var container = selection.component as ContainerComponent;
        var nodes = rive.file.value.objectsOfType<Node>();

        var node = Node()
          ..name = 'Node ${nodes.length + 1}'
          ..x = 0
          ..y = 0;
        rive.file.value.add(node);

        container.appendChild(node);
      } else {
        print('No selection to parent Node to.');
      }
      rive.file.value.captureJournalEntry();
    },
  ),
  PopupContextItem.separator(),
  PopupContextItem('Shape',
      icon: 'tool-shapes.png',
      select: (rive) => print('SELECT SHAPE!'),
      popup: [
        PopupContextItem(
          'Rectangle',
        ),
        PopupContextItem('Ellipse', popup: [
          PopupContextItem(
            'Rectangle',
          ),
          PopupContextItem('Ellipse', popup: [
            PopupContextItem(
              'Rectangle',
            ),
            PopupContextItem(
              'Ellipse',
            ),
            PopupContextItem(
              'Polygon',
            ),
            PopupContextItem(
              'Star',
            ),
            PopupContextItem(
              'Triangle',
            ),
          ]),
          PopupContextItem(
            'Polygon',
          ),
          PopupContextItem(
            'Star',
          ),
          PopupContextItem(
            'Triangle',
          ),
        ]),
        PopupContextItem(
          'Polygon',
        ),
        PopupContextItem(
          'Star',
        ),
        PopupContextItem(
          'Triangle',
        ),
      ]),
  PopupContextItem('Pen', icon: 'tool-pen'),
  PopupContextItem.separator(),
  PopupContextItem('Artboard'),
  PopupContextItem('Bone'),
  PopupContextItem('Node'),
  PopupContextItem('Solo')
];

class RiveEditorApp extends StatelessWidget {
  final Rive rive;
  final FocusNode focusNode;

  const RiveEditorApp({
    Key key,
    this.rive,
    this.focusNode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var focusScope = FocusScope.of(context);

    return RiveTheme(
      child: ShortcutBindings(
        child: RiveContext(
          rive: rive,
          child: IconCache(
            cache: RiveIconCache(rootBundle),
            child: Builder(
              builder: (context) => CursorView(
                onPointerDown: (details) {
                  focusNode.requestFocus();
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
                              var primary = FocusManager.instance.primaryFocus;
                              rive.onKeyEvent(
                                  defaultKeyBinding,
                                  event,
                                  primary != focusNode &&
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
                            autofocus: true,
                            focusNode: focusNode),
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
        return FilesView();
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
          color: const Color.fromRGBO(60, 60, 60, 1.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.max,
            children: [
              HamburgerPopupButton(),
              TransformPopupButton(),
              CreatePopupButton(),
              const Spacer(),
              ConnectedUsers(),
              ViewScaleDropdown(),
              DesignAnimateToggle(),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              ResizePanel(
                hitSize: resizeEdgeSize,
                direction: ResizeDirection.horizontal,
                side: ResizeSide.end,
                min: 300,
                max: 500,
                child: Container(
                  color: const Color.fromRGBO(50, 50, 50, 1.0),
                  child: ValueListenableBuilder<HierarchyTreeController>(
                    valueListenable: rive.treeController,
                    builder: (context, controller, _) =>
                        HierarchyTreeView(controller: controller),
                  ),
                ),
              ),
              const Expanded(
                child: StagePanel(),
              ),
              ResizePanel(
                hitSize: resizeEdgeSize,
                direction: ResizeDirection.horizontal,
                side: ResizeSide.start,
                min: 235,
                max: 500,
                child: Container(
                  color: const Color.fromRGBO(50, 50, 50, 1.0),
                  child: ListenableBuilder(
                    listenable: rive.selection,
                    builder: (context,
                        SelectionContext<SelectableItem> selection, _) {
                      var artboards = selection.items
                          .whereType<StageArtboard>()
                          .map((stageItem) => stageItem.component)
                          .toList(growable: false);
                      if (artboards.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                child: Text(
                                  "No Selection",
                                  style: TextStyle(
                                    color: ThemeUtils.textWhite,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Container(height: 10.0),
                              Container(
                                child: Text(
                                  "Select something to view its properties and options.",
                                  style: TextStyle(
                                    color: ThemeUtils.textGreyLight,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: [
                          PropertyDual(
                            name: 'Pos',
                            objects: artboards,
                            propertyKeyA: ArtboardBase.xPropertyKey,
                            propertyKeyB: ArtboardBase.yPropertyKey,
                          ),
                          PropertyDual(
                            name: 'Size',
                            objects: artboards,
                            propertyKeyA: ArtboardBase.widthPropertyKey,
                            propertyKeyB: ArtboardBase.heightPropertyKey,
                          ),
                          // selection. PropertyDual()
                        ],
                      );
                    },
                  ),
                ),
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

class StagePanel extends StatelessWidget {
  const StagePanel({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final rive = RiveContext.of(context);
    return Container(
      color: const Color.fromRGBO(29, 29, 29, 1.0),
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
                        },
                        onPointerUp: (details) {
                          RenderBox getBox =
                              context.findRenderObject() as RenderBox;
                          var local = getBox.globalToLocal(details.position);
                          stage.mouseUp(details.buttons, local.dx, local.dy);
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
