import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/model.dart';
import 'package:rive_core/event.dart';
import 'package:rive_core/runtime/runtime_importer.dart';
import 'package:rive_editor/main.dart';
import 'package:rive_editor/rive/alerts/simple_alert.dart';
import 'package:rive_editor/rive/managers/task_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/animation/animation_panel.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/hierarchy_panel.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspector_panel.dart';
import 'package:rive_editor/widgets/resize_panel.dart';
import 'package:rive_editor/widgets/toolbar/connected_users.dart';
import 'package:rive_editor/widgets/toolbar/create_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/hamburger_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/mode_toggle.dart';
import 'package:rive_editor/widgets/toolbar/share_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/transform_popup_button.dart';
import 'package:rive_editor/widgets/toolbar/visibility_toolbar.dart';
import 'package:rive_widgets/listenable_builder.dart';
import 'package:window_utils/window_utils.dart' as win_utils;
import 'package:window_utils/window_utils.dart';

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
  Future<void> _filesDropped(Iterable<DroppedFile> files) async {
    var activeFile = ActiveFile.find(context);
    if (activeFile == null || activeFile.state != OpenFileState.open) {
      return;
    } else {
      // TODO: maybe we're in the files view?
    }

    List<DroppedFile> importedRive = [];
    Map<String, DroppedFile> backendConverting = {};
    TasksApi taskApi;
    bool imported = false;
    for (final file in files) {
      var idx = file.filename.lastIndexOf('.');
      if (idx == -1) {
        continue;
      }
      var ext = file.filename.substring(idx + 1);
      switch (ext) {
        case 'riv':
          var importer = RuntimeImporter(core: activeFile.core);
          try {
            if (importer.import(file.bytes)) {
              importedRive.add(file);
              imported = true;
            }
            // ignore: avoid_catching_errors
          } on UnsupportedError {
            activeFile
                .addAlert(SimpleAlert('${file.filename} is unsupported.'));
          }
          break;
        case 'flr2d':
          taskApi ??= TasksApi(activeFile.rive.api);
          var taskResult = await taskApi.convertFLR(file.bytes);
          if (taskResult != null) {
            backendConverting[taskResult.taskId] = file;
          }
          break;
        case 'svg':
          taskApi ??= TasksApi(activeFile.rive.api);
          var taskResult = await taskApi.convertSVG(file.bytes);
          if (taskResult != null) {
            backendConverting[taskResult.taskId] = file;
          }
          break;
      }
    }
    if (imported) {
      activeFile.core.captureJournalEntry();
    }

    if (importedRive.isNotEmpty) {
      activeFile.addAlert(SimpleAlert(
          'Imported ${importedRive.map((file) => file.filename).join(', ')}.'));
    }
    if (backendConverting.isNotEmpty) {
      var fileNames =
          backendConverting.values.map((file) => file.filename).join(', ');
      activeFile.addAlert(SimpleAlert('Importing $fileNames.'));

      var taskIds = backendConverting.keys.toSet();

      var completer =
          TaskManager().notifyTasks(taskIds, (TaskCompleted result) async {
        if (result.success) {
          try {
            var rivBytes = await taskApi.taskData(result.taskId);
            var importer = RuntimeImporter(core: activeFile.core);
            if (importer.import(rivBytes)) {
              activeFile.addAlert(SimpleAlert(
                  'Imported ${backendConverting[result.taskId].filename}.'));
            }
            activeFile.core.captureJournalEntry();
          } on ApiException {
            activeFile.addAlert(SimpleAlert('Error converting '
                '${backendConverting[result.taskId].filename}.'));
            rethrow;
            // ignore: avoid_catching_errors
          } on UnsupportedError {
            activeFile.addAlert(
                SimpleAlert('${backendConverting[result.taskId].filename} '
                    'is unsupported.'));
            rethrow;
          }
        } else {
          activeFile.addAlert(SimpleAlert('Could not convert '
              '${backendConverting[result.taskId].filename}. '
              'Please contact Rive if the problem persists.'));
        }
      });

      await completer.future.timeout(const Duration(seconds: 30),
          onTimeout: () {
        activeFile.addAlert(SimpleAlert('Timed out converting files.'));
        return null;
      });
    }
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
          case OpenFileState.error:
            return Center(
              child: Text(file.stateInfo ?? 'An error occurred...'),
            );
          case OpenFileState.timeout:
          case OpenFileState.loading:
          case OpenFileState.open:
          case OpenFileState.sleeping:
          default:
            return ColoredBox(
              color: const Color(0xFF1D1D1D),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.only(
                              top: 6, bottom: 6, left: 8, right: 6),
                          height: 42,
                          color: const Color.fromRGBO(60, 60, 60, 1),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.max,
                            children:
                                // Don't show toolbar while loading
                                {OpenFileState.open}.contains(file.state)
                                    ? [
                                        HamburgerPopupButton(),
                                        TransformPopupButton(),
                                        CreatePopupButton(),
                                        SharePopupButton(),
                                        const Spacer(),
                                        ConnectedUsers(rive: rive),
                                        VisibilityPopupButton(),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 10, right: 14),
                                          // child: DesignAnimateToggle(),
                                          child: ValueListenableBuilder<
                                              EditorMode>(
                                            valueListenable: file.mode,
                                            builder: (context, mode, _) =>
                                                ModeToggle(
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
                                      ]
                                    : [],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              ResizePanel(
                                hitOffset: 2,
                                drawOffset: -2,
                                hitSize: RiveTheme.of(context)
                                    .dimensions
                                    .resizeEdgeSize,
                                direction: ResizeDirection.horizontal,
                                side: ResizeSide.end,
                                min: 300,
                                max: 500,
                                child: PanelDecoration(
                                  position: PanelPosition.left,
                                  child: HierarchyPanel(),
                                ),
                              ),
                              const Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 2),
                                  child: StagePanel(),
                                ),
                              ),
                              PanelDecoration(
                                position: PanelPosition.right,
                                child: SizedBox(
                                  width: 235,
                                  child: ColoredBox(
                                    color: RiveTheme.of(context)
                                        .colors
                                        .panelBackgroundDarkGrey,
                                    child: {OpenFileState.open}
                                            .contains(file.state)
                                        ?
                                        // Don't show inspector while loading
                                        const InspectorPanel()
                                        : const SizedBox(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimationPanel(),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: file.state == OpenFileState.open,
                      child: AnimatedContainer(
                        color: file.state == OpenFileState.open
                            ? const Color(0x00000000)
                            : const Color(0x99000000),
                        duration: const Duration(milliseconds: 400),
                      ),
                    ),
                  ),
                  if (file.state == OpenFileState.timeout)
                    Positioned.fill(
                      child: Center(
                        child: CountDown(
                          targetTime: file.nextConnectionAttempt,
                          file: file,
                        ),
                      ),
                    )
                ],
              ),
            );
            break;
        }
      },
    );
  }
}

class CountDown extends StatefulWidget {
  final DateTime targetTime;
  final OpenFileContext file;

  const CountDown({Key key, this.targetTime, this.file}) : super(key: key);

  @override
  _CountDownState createState() => _CountDownState();
}

class _CountDownState extends State<CountDown> {
  Timer _timer;
  Duration timeout;
  Duration remainingTimeout() {
    return Duration(
      milliseconds: max(
        widget.targetTime.difference(DateTime.now()).inMilliseconds,
        0,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    startTimer();
    timeout = remainingTimeout();
  }

  void startTimer() {
    _timer = Timer.periodic(
      // TODO: 4fps probably enough?
      // we're only updating every second afterall
      const Duration(milliseconds: 250),
      (Timer timer) => setState(
        () {
          timeout = remainingTimeout();
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String padZeros(num number, int targetDigits) {
    var output = number.toString();
    if (output.length < targetDigits) {
      output = '0' * (targetDigits - output.length) + output;
    }
    return output;
  }

  num seconds(int seconds) {
    return seconds.remainder(Duration.secondsPerMinute);
  }

  String timeoutString() {
    if (timeout > const Duration(hours: 1)) {
      return '> 1 hour';
    } else if (timeout > const Duration(minutes: 1)) {
      return '${timeout.inMinutes}:${padZeros(seconds(timeout.inSeconds), 2)}';
    } else {
      return '${timeout.inSeconds}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Connection lost, reconnecting in ${timeoutString()}',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(
            height: 10,
          ),
          FlatIconButton(
            label: 'Reconnect now',
            onTap: () {
              widget.file.reconnect();
            },
            color: colors.textButtonLight,
            textColor: colors.buttonLightText,
            hoverColor: colors.textButtonLightHover,
            hoverTextColor: colors.buttonLightText,
            radius: 20,
            mainAxisAlignment: MainAxisAlignment.center,
          )
        ],
      ),
    );
  }
}

enum PanelPosition { left, right }

class PanelDecoration extends StatelessWidget {
  final Widget child;
  final PanelPosition position;

  const PanelDecoration({
    @required this.child,
    @required this.position,
    Key key,
  }) : super(key: key);

  BorderRadius _borderRadius() {
    switch (position) {
      case PanelPosition.left:
        return const BorderRadius.only(
          topRight: Radius.circular(5.0),
          bottomRight: Radius.circular(5.0),
        );
      case PanelPosition.right:
        return const BorderRadius.only(
          topLeft: Radius.circular(5.0),
          bottomLeft: Radius.circular(5.0),
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: ClipRRect(
        borderRadius: _borderRadius(),
        child: child,
      ),
    );
  }
}
