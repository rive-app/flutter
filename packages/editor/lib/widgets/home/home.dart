import 'package:cursor/propagating_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/home/file_browser.dart';
import 'package:rive_editor/widgets/home/get_started.dart';
import 'package:rive_editor/widgets/home/navigation_panel.dart';
import 'package:rive_editor/widgets/home/simple_file_browser.dart';
import 'package:rive_editor/widgets/home/team_detail_panel.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/notifications.dart';
import 'package:rive_editor/widgets/resize_panel.dart';

/// This is stateful so we can decide what panel should
/// initially be shown when the app starts up
class Home extends StatefulWidget {
  Home({Key key}) : super(key: key) {
    FolderContentsManager();
  }

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    // TODO: having this logic at the ui level seems wrong,
    // and having it distributed amongst several managers lead
    // to race conditions (which is why it's moved here). This
    // should probably be centralized to a single manager,
    // most likely RiveManager, or a new HomeManager.

    // Check whether the first run flag is set for the user.
    // If it is, show the getting started section
    final me = Plumber().peek<Me>();
    if (Plumber().peek<HomeSection>() == null) {
      if (me.isFirstRun) {
        Plumber().message<HomeSection>(HomeSection.getStarted);
      }
      // If this isn't a first run, then show the user's recent files
      else {
        Plumber().message<HomeSection>(HomeSection.recents);
      }
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return PropagatingListener(
      behavior: HitTestBehavior.deferToChild,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ResizePanel(
            hitSize: theme.dimensions.resizeEdgeSize,
            direction: ResizeDirection.horizontal,
            side: ResizeSide.end,
            min: 252,
            max: 500,
            child: const NavigationPanel(),
          ),
          ValueStreamBuilder<HomeSection>(
            stream: Plumber().getStream<HomeSection>(),
            builder: (context, snapshot) {
              switch (snapshot.data) {
                case HomeSection.files:
                  return Expanded(
                    child: ColoredBox(
                      color: Colors.white,
                      child: FileBrowserWrapper(),
                    ),
                  );

                case HomeSection.notifications:
                  return Expanded(
                    child: ColoredBox(
                      color: Colors.white,
                      child: NotificationsPanel(),
                    ),
                  );

                case HomeSection.community:
                  return const Text('Build community');

                case HomeSection.recents:
                  return Expanded(
                    child: ColoredBox(
                      color: Colors.white,
                      child: SimpleFileBrowserWrapper(
                        files: FileManager().loadRecentFiles(),
                      ),
                    ),
                  );

                case HomeSection.getStarted:
                  return Expanded(
                    child: ColoredBox(
                      color: Colors.white,
                      child: GetStartedPanel(),
                    ),
                  );

                default:
                  return const Text('loading...');
              }
            },
          ),
          ValueStreamBuilder<CurrentDirectory>(
            stream: Plumber().getStream<CurrentDirectory>(),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data.owner is Team) {
                return ResizePanel(
                  hitSize: theme.dimensions.resizeEdgeSize,
                  direction: ResizeDirection.horizontal,
                  side: ResizeSide.start,
                  min: 252,
                  max: 500,
                  child: TeamDetailPanel(team: snapshot.data.owner as Team),
                );
              } else {
                return Container();
              }
            },
          )
        ],
      ),
    );
  }
}
