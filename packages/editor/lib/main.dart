import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:cursor/cursor_view.dart';
import 'package:rive_editor/rive/managers/image_manager.dart';
import 'package:rive_editor/rive/managers/rive_manager.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/widgets/hierarchy_panel.dart';
import 'package:rive_editor/widgets/ui_strings.dart';

import 'package:window_utils/window_utils.dart' as win_utils;

import 'package:core/error_logger/error_logger.dart';
import 'package:rive_core/event.dart';

import 'package:rive_editor/version.dart';
import 'package:rive_editor/widgets/animation/animation_panel.dart';
import 'package:rive_editor/constants.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/managers/follow_manager.dart';
import 'package:rive_editor/rive/managers/notification_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/catastrophe.dart';
import 'package:rive_editor/widgets/common/active_artboard.dart';
import 'package:rive_editor/widgets/disconnected_screen.dart';
import 'package:rive_editor/widgets/home/home_panel.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspector_panel.dart';
import 'package:rive_editor/widgets/stage_late_view.dart';
import 'package:rive_editor/widgets/toolbar/mode_toggle.dart';
import 'package:rive_widgets/listenable_builder.dart';
import 'package:rive_editor/widgets/login.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/resize_panel.dart';
import 'package:rive_editor/widgets/stage_view.dart';
import 'package:rive_editor/widgets/tab_bar/rive_tab_bar.dart';
import 'package:rive_editor/widgets/toolbar/connected_users.dart';
import 'package:rive_editor/widgets/toolbar/create_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/hamburger_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/share_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/transform_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/visibility_toolbar.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorLogger.instance.reportException(details.exception, details.stack);
  };

  WidgetsFlutterBinding.ensureInitialized();
  WidgetsBinding.instance.addPostFrameCallback(
    (_) {
      win_utils.hideTitleBar();
      win_utils.setSize(kDefaultWIndowSize);
    },
  );

  final iconCache = RiveIconCache(rootBundle);
  final rive = Rive(
    iconCache: iconCache,
  );

  // if (await rive.initialize() != RiveState.catastrophe) {
  //   // this is just for the prototype...
  //   // await rive.open('100/100');
  // }

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
        ErrorLogger.instance.reportException(error, stackTrace);
      } on Exception catch (e) {
        debugPrint('Failed to report: $e');
        debugPrint('Error was: $error, $stackTrace');
      }
    },
  );
}

GlobalKey loadingScreenKey = GlobalKey();

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
    final riveManager = RiveManager(rive);

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
                child: Scaffold(
                  body: LoadingScreen(
                    key: loadingScreenKey,
                    rive: rive,
                    child: Focus(
                      focusNode: rive.focusNode,
                      child: ValueListenableBuilder<RiveState>(
                        valueListenable: rive.state,
                        builder: (context, state, _) {
                          switch (state) {
                            case RiveState.login:
                              return Login();

                            case RiveState.editor:
                              return NotificationProvider(
                                manager: NotificationManager(
                                    api: rive.api,
                                    teamUpdateSink: riveManager.teamUpdateSink),
                                child: FollowProvider(
                                  manager: FollowManager(
                                    api: rive.api,
                                    ownerId: rive.user.value.ownerId,
                                  ),
                                  child: const EditorScaffold(),
                                ),
                              );
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
    return UIStrings(
      child: RiveTheme(
        child: ShortcutBindings(
          child: RiveContext(
            rive: rive,
            child: TipRoot(
              context: TipContext(),
              child: ImageCacheProvider(
                manager: ImageManager(),
                child: IconCache(
                  cache: iconCache,
                  // TODO: This should probably get refactored too. It's really
                  // important that it's provided at this level so that popups
                  // shown by the Overlay (which I think is currently generated
                  // by MaterialApp we inject in RiveEditorApp) have access to
                  // the ActiveFile.
                  child: ValueListenableBuilder<OpenFileContext>(
                    valueListenable: rive.file,
                    builder: (context, file, child) =>
                        // Propagate down the active file so other widgets can
                        // determine it without looking for the rive context.
                        ActiveFile(
                      file: file,
                      child: ActiveArtboard(
                        file: file,
                        child: AnimationInheritedWidgets(
                          child: child,
                        ),
                      ),
                    ),
                    // Passing the child in separate from the value listenable
                    // builder as anything interested in the ActiveFile will
                    // .of() from the context anyway to trigger a rebuild.
                    child: child,
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

class AnimationInheritedWidgets extends StatelessWidget {
  final Widget child;

  const AnimationInheritedWidgets({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var activeFile = ActiveFile.of(context);
    if (activeFile == null) {
      return child;
    }
    return ValueListenableBuilder(
      valueListenable: activeFile.mode,
      builder: (context, EditorMode mode, _) {
        return mode == EditorMode.animate
            ? AnimationsProvider(
                activeArtboard: ActiveArtboard.of(context),
                child: EditingAnimationProvider(child: child),
              )
            : child;
      },
    );
  }
}

class Editor extends StatelessWidget {
  const Editor();

  @override
  Widget build(BuildContext context) {
    // No need to depend on Rive as it never changes, so we can use find()
    // instead of of().
    final rive = RiveContext.find(context);

    // Active file can change, so let's depend on it.
    final file = ActiveFile.of(context);
    if (file == null) {
      return const CircularProgressIndicator();
    }

    return ListenableBuilder<Event>(
      listenable: file.stateChanged,
      builder: (context, event, _) {
        switch (file.state) {
          case OpenFileState.loading:
            return Container(
              color: RiveTheme.of(context).colors.stageBackground,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
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
                        padding: const EdgeInsets.only(left: 10, right: 14),
                        // child: DesignAnimateToggle(),
                        child: ValueListenableBuilder<EditorMode>(
                          valueListenable: file.mode,
                          builder: (context, mode, _) => ModeToggle(
                            modes: const [
                              EditorMode.design,
                              EditorMode.animate,
                            ],
                            selected: mode,
                            label: (EditorMode mode) {
                              switch (mode) {
                                case EditorMode.design:
                                  return 'Design';
                                case EditorMode.animate:
                                default:
                                  return 'Animate';
                              }
                            },
                            select: (EditorMode mode) {
                              file.mode.value = mode;
                              // If animate mode is selected, automatically
                              // select the translate tool
                              if (mode == EditorMode.animate) {
                                file.rive.triggerAction(
                                  ShortcutAction.translateTool,
                                );
                              }
                            },
                          ),
                        ),
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
                      ResizePanel(
                        hitSize:
                            RiveTheme.of(context).dimensions.resizeEdgeSize,
                        direction: ResizeDirection.horizontal,
                        side: ResizeSide.start,
                        min: 235,
                        max: 500,
                        child: const InspectorPanel(),
                      ),
                    ],
                  ),
                ),
                AnimationPanel(),
              ],
            );
            break;
        }
      },
    );
  }
}

/// Window chrome and tab bar for the editor.
class EditorScaffold extends StatelessWidget {
  const EditorScaffold({this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rive = RiveContext.of(context);

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
                        onTapDown: (_) => win_utils.startDrag(),
                      ),
                    ),
                    _TabBar(rive: rive),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 10, right: 20),
                child: Text(
                  'v$appVersion',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ValueListenableBuilder<RiveTabItem>(
              valueListenable: rive.selectedTab,
              builder: (context, tab, _) {
                switch (tab) {
                  case Rive.systemTab:
                    return const Home();
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
      left: RiveTheme.of(context).platform.leftOffset,
      top: 0,
      bottom: 0,
      right: 0,
      child: ListenableBuilder<Event>(
        listenable: rive.fileTabsChanged,
        builder: (context, _, child) => ValueListenableBuilder<RiveTabItem>(
          valueListenable: rive.selectedTab,
          builder: (context, tab, child) => DockingTabBar(
            selectedTab: tab,
            dockedTabs: const [
              Rive.systemTab,
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

/// The central stage panel, where drawing/composing takes place
class StagePanel extends StatelessWidget {
  const StagePanel({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final file = ActiveFile.of(context);
    var stage = file.stage;
    var theme = RiveTheme.of(context);
    var resizeEdgeSize = theme.dimensions.resizeEdgeSize;
    return Stack(
      children: [
        Positioned.fill(
          child: stage == null
              ? Container()
              : StageView(
                  file: file,
                  stage: stage,
                  customCursor: CustomCursor.of(context),
                ),
        ),
        Positioned.fill(
          child: stage == null
              ? Container()
              : StageLateView(
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

/// Loading screen that displays while Rive state is loading/initializing
class LoadingScreen extends StatefulWidget {
  const LoadingScreen({this.rive, this.child, Key key}) : super(key: key);
  final Rive rive;
  final Widget child;

  @override
  _LoadingScreenState createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  // Remember if Rive is initialized
  bool _initialized = false;

  @override
  void initState() {
    _initialize();
    super.initState();
  }

  Future<void> _initialize() async {
    final state = await widget.rive.initialize();
    print('State is $state');
    if (state == RiveState.catastrophe) {
      throw Exception('Catastrophe initializing Rive');
    }
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) => _initialized
      ? widget.child
      : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'Loading Rive 2 v$appVersion',
                style: TextStyle(fontSize: 24),
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(),
            ],
          ),
        );
}
