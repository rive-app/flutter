import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/model.dart' as model;
import 'package:rive_api/model.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/managers/announcements_manager.dart';
import 'package:rive_editor/rive/managers/folder_tree_manager.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/common/dashed_flat_button.dart';
import 'package:rive_editor/widgets/common/icon_tile.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/team_wizard.dart';
import 'package:rive_editor/widgets/home/folder_tree.dart';
import 'package:rive_editor/widgets/home/sliver_inline_footer.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:tree_widget/tree_scroll_view.dart';
import 'package:tree_widget/tree_style.dart';

import 'package:rive_api/plumber.dart';

const kTreeItemHeight = 35.0;

class NavigationPanel extends StatefulWidget {
  const NavigationPanel({
    Key key,
  }) : super(key: key);

  @override
  _NavigationPanelState createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  bool _bottomSliverDocked = false;
  bool get bottomSliverDocked => _bottomSliverDocked;
  ScrollController scrollController;

  set bottomSliverDocked(bool bottomSliverDocked) {
    if (_bottomSliverDocked != bottomSliverDocked) {
      setState(() {
        _bottomSliverDocked = bottomSliverDocked;
      });
    }
  }

  @override
  void initState() {
    scrollController = ScrollController();

    var manager = FolderTreeManager();
    manager.scrollController = scrollController;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    scrollController.addListener(() {
      // this KINDA works, sometimes window size changes trigger this
      // sometimes they do not :( Matt will fix it up later though
      bottomSliverDocked = scrollController.position.extentAfter != 0 ||
          scrollController.position.extentBefore != 0;
    });

    final theme = RiveTheme.of(context);
    final riveColors = theme.colors;

    final treeStyle = TreeStyle(
      showFirstLine: false,
      padding: const EdgeInsets.only(
        left: 10,
        right: 10,
        bottom: 10,
        top: 9,
      ),
      lineColor: RiveTheme.of(context).colors.lightTreeLines,
      itemHeight: kTreeItemHeight,
    );

    return Container(
      decoration: BoxDecoration(
        color: riveColors.fileBackgroundLightGrey,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
            child: ValueStreamBuilder<Me>(
              stream: Plumber().getStream<Me>(),
              builder: (context, snapshot) {
                return ValueStreamBuilder<HomeSection>(
                  stream: Plumber().getStream<HomeSection>(),
                  builder: (context, snapshot) {
                    return Column(
                      children: <Widget>[
                        ValueStreamBuilder<Object>(
                            stream: Plumber().getStream<HomeSection>(),
                            builder: (context, snapshot) {
                              return IconTile(
                                icon: PackedIcon.rocket,
                                label: 'Learn',
                                highlight:
                                    snapshot.data == HomeSection.getStarted,
                                onTap: () async =>
                                    Plumber().message(HomeSection.getStarted),
                              );
                            }),
                        ValueStreamBuilder<model.NotificationCount>(
                            stream:
                                Plumber().getStream<model.NotificationCount>(),
                            builder: (context, notificationCountSnapshot) {
                              final notificationCount =
                                  notificationCountSnapshot.hasData
                                      ? notificationCountSnapshot.data.count
                                      : 0;
                              return ValueStreamBuilder<
                                      List<model.Announcement>>(
                                  stream: Plumber()
                                      .getStream<List<model.Announcement>>(),
                                  builder:
                                      (context, notificationCountSnapshot) {
                                    final newAnnoucement =
                                        AnnouncementsManager()
                                            .anyAnnouncementNew(
                                                notificationCountSnapshot.data);

                                    return IconTile(
                                      icon: PackedIcon.notification,
                                      label: 'Notifications',
                                      count: notificationCount,
                                      hasAnnouncement: newAnnoucement,
                                      highlight: snapshot.data ==
                                          HomeSection.notifications,
                                      onTap: () async => Plumber()
                                          .message(HomeSection.notifications),
                                    );
                                  });
                            }),
                        IconTile(
                          icon: PackedIcon.recents,
                          label: 'Recents',
                          highlight: snapshot.data == HomeSection.recents,
                          onTap: () async =>
                              Plumber().message(HomeSection.recents),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Separator(
            color: riveColors.fileLineGrey,
            padding: const EdgeInsets.only(top: 10),
          ),
          Expanded(
            child: ValueStreamBuilder<List<FolderTreeItemController>>(
              stream: Plumber().getStream<List<FolderTreeItemController>>(),
              builder: (context, snapshot) {
                var slivers = <Widget>[];
                if (snapshot.data != null) {
                  for (int i = 0; i < snapshot.data.length; i++) {
                    // TODO: rather than folderTrees we probably rely on this controller?
                    slivers.add(
                      FolderTreeView(
                          style: treeStyle, controller: snapshot.data[i]),
                    );
                    if (i != snapshot.data.length - 1) {
                      slivers.add(
                        SliverToBoxAdapter(
                          child: Separator(
                            color: riveColors.fileLineGrey,
                            padding: const EdgeInsets.only(
                              left: 20,
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }
                slivers.add(
                  SliverInlineFooter(
                    child: Container(
                      decoration: BoxDecoration(
                        color: riveColors.fileBackgroundLightGrey,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Separator(
                            color: riveColors.fileLineGrey,
                            padding: EdgeInsets.only(
                              left: bottomSliverDocked ? 0 : 20,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 20,
                              bottom: 20,
                              top: 20,
                            ),
                            child: DashedFlatButton(
                              label: 'New Team',
                              icon: PackedIcon.teamsButton,
                              textColor: const Color(0xFF888888),
                              iconColor: const Color(0xFFA9A9A9),
                              hoverTextColor: const Color(0xFF666666),
                              hoverIconColor: const Color(0xFF888888),
                              tip: const Tip(
                                label: 'Create a space where you and'
                                    '\nyour team can share files.',
                                direction: PopupDirection.bottomToCenter,
                                fallbackDirections: [
                                  PopupDirection.topToCenter,
                                ],
                              ),
                              onTap: () => showTeamWizard<void>(
                                context: context,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                return TreeScrollView(
                  scrollController: scrollController,
                  slivers: slivers,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
