import 'dart:async';
import 'dart:ui';

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
import 'package:rive_editor/alerts_display.dart';
import 'package:rive_editor/editor.dart';
import 'package:rive_editor/external_url.dart';
import 'package:rive_editor/global_messages.dart';
import 'package:rive_editor/rive/managers/global_message_manager.dart';
import 'package:rive_editor/rive/managers/image_manager.dart';
import 'package:rive_editor/rive/managers/rive_manager.dart';
import 'package:rive_editor/rive/managers/websocket_comms_manager.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_actions.dart';
import 'package:rive_editor/rive/stage/stage.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/ui_strings.dart';

import 'package:window_utils/window_utils.dart' as win_utils;

import 'package:rive_api/plumber.dart';
import 'package:rive_core/event.dart';
import 'package:rive_editor/constants.dart';
import 'package:rive_editor/rive/image_cache.dart';
import 'package:rive_editor/rive/managers/notification_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/version.dart';
import 'package:rive_editor/widgets/catastrophe.dart';
import 'package:rive_editor/widgets/disconnected_screen.dart';
import 'package:rive_editor/widgets/home/home.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/login/login.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/stage_late_view.dart';
import 'package:rive_editor/widgets/stage_view.dart';
import 'package:rive_editor/widgets/tab_bar/rive_tab_bar.dart';
import 'package:rive_widgets/listenable_builder.dart';

Future<void> main() async {
  FlutterError.onError = (FlutterErrorDetails details) {
    ErrorLogger.instance.reportException(details.exception, details.stack);
  };

  WidgetsFlutterBinding.ensureInitialized();

  final imageCache = RiveImageCache(rootBundle);
  final rive = Rive(
    imageCache: imageCache,
  );

  unawaited(rive.initialize());
  UserManager();
  TeamManager();
  FileManager();
  SelectionManager();
  RiveManager().rive = rive;
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
            imageCache: imageCache,
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
    _initWindow();
    // debounce(_initWindow, duration: const Duration(seconds: 1));
  }

  void _initWindow() {
    win_utils.hideTitleBar();
    win_utils.setSize(kDefaultWIndowSize);
    win_utils.initInputHelper();
    win_utils.setMinWindowSize(const Size(600, 500));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

GlobalKey loadingScreenKey = GlobalKey();

class CursorHandler extends StatelessWidget {
  final Rive rive;

  const CursorHandler({
    @required this.rive,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CursorView(
      onMoved: () {
        final file = ActiveFile.find(context);
        file?.delaySleep();
      },
      onPointerDown: (details) {
        // If we click anywhere, suppress any ShortcutAction.togglePlay that
        // may be pressed. #811
        rive.cancelPress(ShortcutAction.togglePlay);

        rive.focusNode.requestFocus();
      },
      child: RiveEditorApp(
        rive: rive,
      ),
    );
  }
}

class RiveEditorShell extends StatelessWidget {
  final Rive rive;
  final RiveImageCache imageCache;

  const RiveEditorShell({
    Key key,
    this.rive,
    this.imageCache,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InsertInheritedWidgets(
      rive: rive,
      imageCache: imageCache,
      child: CursorHandler(rive: rive),
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
      title: 'Rive',
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
                    return const EditorScaffold();

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
  const InsertInheritedWidgets({this.rive, this.imageCache, this.child});
  final Rive rive;
  final RiveImageCache imageCache;
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
                child: ImageAssetCache(
                  cache: imageCache,
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
