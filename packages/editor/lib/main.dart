import 'dart:async';
import 'dart:ui';

import 'package:core/debounce.dart';
import 'package:core/error_logger/error_logger.dart';
import 'package:core/error_logger/native_error_logger.dart';
import 'package:cursor/cursor_view.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pedantic/pedantic.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_core/runtime/runtime_importer.dart';
import 'package:rive_editor/alerts_display.dart';
import 'package:rive_editor/external_url.dart';
import 'package:rive_editor/global_messages.dart';
import 'package:rive_editor/rive/alerts/simple_alert.dart';
import 'package:rive_editor/rive/managers/global_message_manager.dart';
import 'package:rive_editor/rive/managers/image_manager.dart';
import 'package:rive_editor/rive/managers/rive_manager.dart';
import 'package:rive_editor/rive/managers/websocket_comms_manager.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/hierarchy_panel.dart';
import 'package:rive_editor/widgets/toolbar/share_popup_button.dart';
import 'package:rive_editor/widgets/ui_strings.dart';

import 'package:window_utils/window_utils.dart' as win_utils;

import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_core/event.dart';
import 'package:rive_editor/constants.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/managers/follow_manager.dart';
import 'package:rive_editor/rive/managers/notification_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/version.dart';
import 'package:rive_editor/widgets/animation/animation_panel.dart';
import 'package:rive_editor/widgets/catastrophe.dart';
import 'package:rive_editor/widgets/disconnected_screen.dart';
import 'package:rive_editor/widgets/home/home.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspector_panel.dart';
import 'package:rive_editor/widgets/login/login.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/stage_late_view.dart';
import 'package:rive_editor/widgets/stage_view.dart';
import 'package:rive_editor/widgets/tab_bar/rive_tab_bar.dart';
import 'package:rive_editor/widgets/toolbar/connected_users.dart';
import 'package:rive_editor/widgets/toolbar/create_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/hamburger_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/mode_toggle.dart';
import 'package:rive_editor/widgets/toolbar/transform_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/visibility_toolbar.dart';
import 'package:rive_widgets/listenable_builder.dart';
import 'package:window_utils/window_utils.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorLogger.instance.reportException(details.exception, details.stack);
  };

  WidgetsFlutterBinding.ensureInitialized();

  final iconCache = RiveIconCache(rootBundle);
  final rive = Rive(
    iconCache: iconCache,
  );

  unawaited(rive.initialize());
  UserManager();
  TeamManager();
  FileManager();
  SelectionManager();
  RiveManager();
  NotificationManager();
  WebsocketCommsManager();
  GlobalMessageManager();

  // Runs the app in a custom [Zone] (i.e. an execution context).
  // Provides a convenient way to capture all errors, so they can be reported
  // to our logger service.
  await runZonedGuarded<Future<void>>(
    () async {
      var zone = Zone.current;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (isInDebugMode) {
          FlutterError.dumpErrorToConsole(details);
          return;
        }

        // Figure out if we want to let the app limp along in debug mode...If
        // so, move this catastrophe pipe to after the return.
        Plumber().message<AppState>(AppState.catastrophe);

        zone.handleUncaughtError(details.exception, details.stack);
      };
      runApp(
        InitWindowWidget(
          child: RiveEditorShell(
            rive: rive,
            iconCache: iconCache,
          ),
        ),
      );
    },
    (Object error, StackTrace stackTrace) {
      try {
        ErrorLogger.instance.reportException(error, stackTrace);
      } on Exception catch (e) {
        debugPrint('Failed to report: $e');
        debugPrint('Error was: $error, $stackTrace');
      }
    },
  );
}

class InitWindowWidget extends StatefulWidget {
  final Widget child;

  const InitWindowWidget({Key key, this.child}) : super(key: key);
  @override
  _InitWindowWidgetState createState() => _InitWindowWidgetState();
}

class _InitWindowWidgetState extends State<InitWindowWidget> {
  @override
  void initState() {
    super.initState();
    debounce(_initWindow, duration: const Duration(seconds: 1));
  }

  void _initWindow() {
    win_utils.hideTitleBar();
    win_utils.setSize(kDefaultWIndowSize);
    win_utils.initInputHelper();
    win_utils.listenFilesDropped((files) {
      print("We got $files");
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

GlobalKey loadingScreenKey = GlobalKey();

class RiveEditorShell extends StatelessWidget {
  final Rive rive;
  final RiveIconCache iconCache;

  const RiveEditorShell({
    Key key,
    this.rive,
    this.iconCache,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InsertInheritedWidgets(
      rive: rive,
      iconCache: iconCache,
      child: CursorView(
        onPointerDown: (details) {
          // If we click anywhere, suppress any ShortcutAction.togglePlay that
          // may be pressed. #811
          rive.cancelPress(ShortcutAction.togglePlay);

          rive.focusNode.requestFocus();
        },
        child: RiveEditorApp(
          rive: rive,
        ),
      ),
    );
  }
}

class RiveEditorApp extends StatelessWidget {
  final Rive rive;

  const RiveEditorApp({
    @required this.rive,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Rive",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      home: DefaultTextStyle(
        style: RiveTheme.of(context).textStyles.basic,
        child: Scaffold(
          body: Focus(
            focusNode: rive.focusNode,
            child: ValueStreamBuilder<AppState>(
              stream: Plumber().getStream<AppState>(),
              builder: (context, snapshot) {
                switch (snapshot.data) {
                  case AppState.login:
                    return Login();

                  case AppState.home:
                    return FollowProvider(
                      manager: FollowManager(
                        api: rive.api,
                        ownerId: Plumber().peek<Me>().ownerId,
                      ),
                      child: const EditorScaffold(),
                    );

                  case AppState.disconnected:
                    return DisconnectedScreen();
                    break;

                  case AppState.catastrophe:
                    return Catastrophe();

                  default:
                    return const LoadingScreen();
                }
              },
            ),
          ),
        ),
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
                    builder: (context, file, child) {
                      // Propagate down the active file so other widgets can
                      // determine it without looking for the rive context.
                      return ActiveFile(file: file, child: child);
                    },
                    // Passing the child in separate from the value listenable
                    // builder as anything interested in the ActiveFile will
                    // .of() from the context anyway to trigger a rebuild.
                    child: KeyPressProvider(
                      listener: rive.onRawKeyPress,
                      child: child,
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

/// TODO: We converted Editor to a stateful widget so that we can easily detect
/// at the UI layer when we're in the editor (and not plumb it in Rive or
/// something else). This should get cleaned up when the file drop is moved into
/// the FileBrowser and handled by the API layer instead.
class Editor extends StatefulWidget {
  const Editor();

  @override
  _EditorState createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  void _filesDropped(Iterable<DroppedFile> files) {
    var activeFile = ActiveFile.find(context);
    if (activeFile == null || activeFile.state != OpenFileState.open) {
      return;
    }

    List<DroppedFile> importedFiles = [];
    bool imported = false;
    for (final file in files) {
      if (file.filename.endsWith('.riv')) {
        var importer = RuntimeImporter(core: activeFile.core);
        if (importer.import(file.bytes)) {
          importedFiles.add(file);
          imported = true;
        }
      }
    }
    if (imported) {
      activeFile.core.captureJournalEntry();
    }

    activeFile.addAlert(SimpleAlert(
        'Imported ${importedFiles.map((file) => file.filename).join(', ')}.'));
  }

  @override
  void initState() {
    win_utils.listenFilesDropped(_filesDropped);
    super.initState();
  }

  @override
  void dispose() {
    win_utils.cancelFilesDropped(_filesDropped);
    super.dispose();
  }

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
                  padding: const EdgeInsets.only(
                      top: 6, bottom: 6, left: 8, right: 6),
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
                              file.changeMode(mode);
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
                      const SizedBox(
                        width: 235,
                        child: InspectorPanel(),
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
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: FeedbackButton(),
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
          child: Stack(
            children: [
              ValueListenableBuilder<RiveTabItem>(
                valueListenable: rive.selectedTab,
                builder: (context, tab, _) {
                  switch (tab) {
                    case Rive.systemTab:
                      return Home();
                    default:
                      return const Editor();
                  }
                },
              ),
              Positioned.fill(
                child: GlobalMessages(),
              ),
            ],
          ),
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
    var theme = RiveTheme.of(context);
    var resizeEdgeSize = theme.dimensions.resizeEdgeSize;
    return ValueListenableBuilder(
      valueListenable: file.stageListenable,
      builder: (context, Stage stage, _) {
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
                        RenderBox getBox =
                            context.findRenderObject() as RenderBox;
                        var local = getBox.globalToLocal(details.position);
                        stage.mouseExit(details.buttons, local.dx, local.dy);
                      },
                      onEnter: (details) {
                        RenderBox getBox =
                            context.findRenderObject() as RenderBox;
                        var local = getBox.globalToLocal(details.position);
                        stage.mouseEnter(details.buttons, local.dx, local.dy);
                      },
                      onHover: (details) {
                        RenderBox getBox =
                            context.findRenderObject() as RenderBox;
                        var local = getBox.globalToLocal(details.position);
                        stage.mouseMove(details.buttons, local.dx, local.dy);
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
            Positioned.fill(
              child: AlertsDisplay(),
            ),
          ],
        );
      },
    );
  }
}

/// Loading screen that displays while Rive state is loading/initializing
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
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

class FeedbackButton extends StatelessWidget {
  const FeedbackButton();

  @override
  Widget build(BuildContext context) {
    return const FlatButton(
      child: Text(
        'Feedback',
        style: TextStyle(color: Colors.grey),
      ),
      onPressed: launchSupportUrl,
    );
  }
}
