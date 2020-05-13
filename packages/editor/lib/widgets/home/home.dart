import 'package:cursor/propagating_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/widgets/home/file_browser.dart';
import 'package:rive_editor/widgets/home/navigation_panel.dart';
import 'package:rive_editor/widgets/home/team_detail_panel.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/resize_panel.dart';

class Home extends StatelessWidget {
  Home({Key key}) : super(key: key) {
    UserManager().loadMe();
    FolderContentsManager();
  }

  bool get isTeam => false;

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
          const Expanded(
            child: ColoredBox(
              color: Colors.white,
              child: FileBrowser(),
            ),
          ),
          StreamBuilder<CurrentDirectory>(
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
          ),
        ],
      ),
    );
  }
}
