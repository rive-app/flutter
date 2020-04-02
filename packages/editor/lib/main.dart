import 'dart:async';

import 'package:cursor/propagating_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:core/debounce.dart';

import 'package:cursor/cursor_view.dart';
import 'package:rive_api/artists.dart';
import 'package:rive_api/models/user.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';

import 'package:window_utils/window_utils.dart';

import 'package:core/error_logger.dart';
import 'package:rive_core/event.dart';

import 'package:rive_editor/constants.dart';

import 'package:rive_editor/rive/hierarchy_tree_controller.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/draw_order_tree_controller.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/shortcuts/default_key_binding.dart';

import 'package:rive_editor/widgets/changelog.dart';
import 'package:rive_editor/widgets/disconnected_screen.dart';
import 'package:rive_editor/widgets/draw_order.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/listenable_builder.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/toolbar/connected_users.dart';
import 'package:rive_editor/widgets/toolbar/create_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/design_animate_toggle.dart';
import 'package:rive_editor/widgets/toolbar/hamburger_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/share_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/transform_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/visibility_toolbar.dart';
import 'package:rive_editor/widgets/catastrophe.dart';
import 'package:rive_editor/widgets/home/home_panel.dart';
import 'package:rive_editor/widgets/hierarchy.dart';
import 'package:rive_editor/widgets/inspector/inspector_panel.dart';
import 'package:rive_editor/widgets/login.dart';
import 'package:rive_editor/widgets/resize_panel.dart';
import 'package:rive_editor/widgets/stage_view.dart';
import 'package:rive_editor/widgets/tab_bar/rive_tab_bar.dart';

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
    return InsertInheritedWidgets(
      rive: rive,
      iconCache: iconCache,
      child: Builder(
        builder: (context) {
          return CursorView(
            onPointerDown: (details) => rive.focusNode.requestFocus(),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData.light(),
              home: DefaultTextStyle(
                style: RiveTheme.of(context).textStyles.basic,
                child: Container(
                  child: Scaffold(
                    body: RawKeyboardListener(
                      focusNode: rive.focusNode,
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
                              return EditorScaffold();

                            case RiveState.disconnected:
                              return DisconnectedScreen();
                              break;

                            case RiveState.catastrophe:
                            default:
                              return Catastrophe();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper widget if inserting inherited widgets into the
/// top of the widget tree. Any new inherited widgets should go
/// in here.
class InsertInheritedWidgets extends StatelessWidget {
  const InsertInheritedWidgets({this.rive, this.iconCache, this.child});
  final Rive rive;
  final RiveIconCache iconCache;
  final Widget child;

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
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class Editor extends StatelessWidget {
  const Editor();

  @override
  Widget build(BuildContext context) {
    final rive = RiveContext.of(context);
    return ValueListenableBuilder<OpenFileContext>(
      valueListenable: rive.file,
      builder: (context, file, child) =>
          // Propagate down the active file so other widgets can determine it
          // without looking for the rive context.
          ActiveFile(
        file: file,
        child: ListenableBuilder<Event>(
          listenable: file.stateChanged,
          builder: (context, event, _) {
            switch (file.state) {
              case OpenFileState.loading:
                return const Center(
                  child: CircularProgressIndicator(),
                );
              case OpenFileState.error:
                return const Center(
                  child: Text('An error occurred...'),
                );
              case OpenFileState.open:
              default:
                return Column(
                  children: [
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
                        ],
                      ),
                    ),
                  ],
                );
                break;
            }
          },
        ),
      ),
    );
  }
}

/// Window chrome and tab bar for the editor.
class EditorScaffold extends StatelessWidget {
  const EditorScaffold({this.child});
  final Widget child;

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
                        onTapDown: (_) => WindowUtils.startDrag(),
                      ),
                    ),
                    _TabBar(rive: rive),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<RiveTabItem>(
              valueListenable: rive.selectedTab,
              builder: (context, tab, _) {
                // Unleash this demon if you want to invite your friends to play
                // with comboboxes.
                // return Center(
                //   child: InvitePanel(rive: rive),
                // );
                switch (tab) {
                  case Rive.systemTab:
                    return const Home();
                  case Rive.changeLogTab:
                    return const ChangeLog();
                  default:
                    return const Editor();
                }
              }),
        ),
      ],
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({
    @required this.rive,
    Key key,
  }) : super(key: key);

  final Rive rive;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 95,
      top: 0,
      bottom: 0,
      right: 0,
      child: ListenableBuilder<Event>(
        listenable: rive.fileTabsChanged,
        builder: (context, _, child) => ValueListenableBuilder<RiveTabItem>(
          valueListenable: rive.selectedTab,
          builder: (context, tab, child) => DockingTabBar(
            selectedTab: tab,
            dockedTabs: [
              Rive.systemTab,
              Rive.changeLogTab,
            ],
            dynamicTabs: rive.fileTabs,
            select: rive.selectTab,
            close: rive.closeTab,
          ),
        ),
      ),
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
    final file = ActiveFile.of(context);
    var theme = RiveTheme.of(context);
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
            Row(
              children: <Widget>[
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
                              ? theme.textStyles.hierarchyTabActive
                              : hierarchyHovered
                                  ? theme.textStyles.hierarchyTabHovered
                                  : theme.textStyles.hierarchyTabInactive),
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
                                  ? theme.textStyles.hierarchyTabHovered
                                  : theme.textStyles.hierarchyTabInactive
                              : theme.textStyles.hierarchyTabActive),
                    ),
                  ),
                ),
              ],
            ),
            if (hierarchySelected)
              Expanded(
                child: ValueListenableBuilder<HierarchyTreeController>(
                  valueListenable: file.treeController,
                  builder: (context, controller, _) =>
                      HierarchyTreeView(controller: controller),
                ),
              ),
            if (!hierarchySelected)
              Expanded(
                // child: DrawOrder(),
                child: ValueListenableBuilder<DrawOrderTreeController>(
                  valueListenable: file.drawOrderTreeController,
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
    final file = ActiveFile.of(context);
    var stage = file.stage;

    return Stack(
      children: [
        Positioned.fill(
          child: stage == null
              ? Container()
              : StageView(
                  file: file,
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
                    RenderBox getBox = context.findRenderObject() as RenderBox;
                    var local = getBox.globalToLocal(details.position);
                    stage.mouseExit(details.buttons, local.dx, local.dy);
                  },
                  onHover: (details) {
                    RenderBox getBox = context.findRenderObject() as RenderBox;
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
                      file.rive.startDragOperation();
                    },
                    onPointerUp: (details) {
                      RenderBox getBox =
                          context.findRenderObject() as RenderBox;
                      var local = getBox.globalToLocal(details.position);
                      stage.mouseUp(details.buttons, local.dx, local.dy);
                      file.rive.endDragOperation();
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
    );
  }
}

class InvitePanel extends StatefulWidget {
  final Rive rive;

  const InvitePanel({Key key, this.rive}) : super(key: key);
  @override
  _InvitePanelState createState() => _InvitePanelState();
}

class _InvitePanelState extends State<InvitePanel> {
  final _invites = [
    const RiveUser(
      ownerId: 1,
      username: '@spengler',
      name: 'Egon Spengler',
    ),
    const RiveUser(
      ownerId: 2,
      username: '@venkman',
      name: 'Peter Venkman',
    ),
    const RiveUser(
      ownerId: 3,
      username: '@zeddemore',
      name: 'Winston Zeddemore',
    ),
    const RiveUser(
      ownerId: 4,
      username: '@stantz',
      name: 'Ray Stantz',
    ),
    const RiveUser(
      ownerId: 5,
      username: '@melnitz',
      name: 'Janine Melnitz',
    ),
  ];

  RiveArtists _api;
  final Event _openCombo = Event();

  @override
  void initState() {
    super.initState();
    _api = RiveArtists(widget.rive.api);
  }

  Future<List<RiveUser>> _autocomplete(String input) =>
      _api.autocomplete(input);

  void _startTypeAhead() {
    _openCombo.notify();
  }

  @override
  void dispose() {
    cancelDebounce(_startTypeAhead);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PropagatingListener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _startTypeAhead(),
      child: Container(
        constraints: const BoxConstraints(minHeight: 30),
        color: Colors.grey,
        width: 488,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ..._invites
                .map(
                  (user) => Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF262626),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.all(5),
                    child: Text(user.displayName),
                  ),
                )
                .toList(growable: false),
            ComboBox<RiveUser>(
              /// Event to trigger (open or typeahead depending on config) the
              /// combobox.
              trigger: _openCombo,
              cursorColor: Colors.black,
              valueColor: Colors.black,
              sizing: ComboSizing.collapsed,
              /// If sizing is set to content, the popup will resize
              /// horizontally to fit the text label (TODO: add option for
              /// avatar/leading widget).
              popupSizing: ComboPopupSizing.content,
              underline: false,
              chevron: false,
              typeahead: true,
              /// A friendly dog, I mean callback, to go retrieve your results
              /// to show in the dropdown. Passes in the typed text.
              retriever: _autocomplete,
              /// No value to start with, this combo is a ghost town.
              value: null,
              /// User selected a value.
              change: (RiveUser selectedUser) {
                setState(() {
                  _invites.add(selectedUser);
                  // TODO: is there a way to call _startTypeahead only after the
                  // next update? gotta debounce otherwise the context doesn't
                  // update fast enough in the combobox and the popup opens in
                  // the wrong spot.
                  debounce(_startTypeAhead);
                });
              },
              /// Maybe make a version of this that is toWidget? or toLeading if
              /// we want to provide the leading and text separately
              toLabel: (RiveUser user) =>
                  '@${user.username} ${user.displayName}',
            ),
          ],
        ),
      ),
    );
  }
}
