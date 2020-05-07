import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/file_browser/browser_tree_controller.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/common/dashed_flat_button.dart';
import 'package:rive_editor/widgets/common/icon_tile.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/team_wizard.dart';
import 'package:rive_editor/widgets/home/folder_tree.dart';
import 'package:rive_editor/widgets/home/sliver_inline_footer.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rxdart/rxdart.dart';
import 'package:tree_widget/tree_scroll_view.dart';
import 'package:tree_widget/tree_style.dart';

import 'package:rive_api/src/manager/manager.dart';
import 'package:rive_api/src/model/model.dart';
import 'package:rive_api/src/plumber.dart';

class NavigationPanel extends StatefulWidget {
  @override
  _NavigationPanelState createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<NavigationPanel> {
  bool _bottomSliverDocked = false;
  bool get bottomSliverDocked => _bottomSliverDocked;

  set bottomSliverDocked(bool bottomSliverDocked) {
    if (_bottomSliverDocked != bottomSliverDocked) {
      // something here is interfering
      // this is getting deleted though. so you know.
      // setState(() {
      //   _bottomSliverDocked = bottomSliverDocked;
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    var scrollController = RiveContext.of(context).treeScrollController;
    scrollController.addListener(() {
      // this KINDA works, sometimes window size changes trigger this
      // sometimes they do not :( Matt will fix it up later though
      bottomSliverDocked = scrollController.position.extentAfter != 0 ||
          scrollController.position.extentBefore != 0;
    });

    final theme = RiveTheme.of(context);
    final rive = RiveContext.of(context);
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

    // this listener is in place to force everything to redraw once the
    // activeFileBrowser chagnes.
    // without this, if you change between teams, only one half of the
    // state changes... (the color of the text, the
    // background comes from within the browser..)
    return Container(
      decoration: BoxDecoration(
        color: riveColors.fileBackgroundLightGrey,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Not Implemented
          // Padding(
          //   padding: const EdgeInsets.only(
          //     right: 20,
          //     left: 20,
          //   ),
          //   child: Container(
          //     height: 35,
          //     padding: const EdgeInsets.only(left: 10, right: 10),
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(5),
          //       color: riveColors.fileSearchBorder,
          //     ),
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       crossAxisAlignment: CrossAxisAlignment.center,
          //       children: <Widget>[
          //         SearchIcon(
          //           color: riveColors.fileSearchIcon,
          //           size: 16,
          //         ),
          //         Container(width: 10),
          //         Expanded(
          //           child: Container(
          //             height: 35,
          //             alignment: Alignment.centerLeft,
          //             child: TextField(
          //               textAlign: TextAlign.left,
          //               textAlignVertical: TextAlignVertical.center,
          //               decoration: InputDecoration(
          //                 isDense: true,
          //                 border: InputBorder.none,
          //                 hintText: 'Search',
          //                 contentPadding: EdgeInsets.zero,
          //                 filled: true,
          //                 hoverColor: Colors.transparent,
          //                 fillColor: Colors.transparent,
          //               ),
          //               style: RiveTheme.of(context).textStyles.fileSearchText,
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
          ValueListenableBuilder<HomeSection>(
            valueListenable: rive.sectionListener,
            builder: (context, section, _) => Padding(
              padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
              child: Column(
                children: <Widget>[
                  // Not currently implemented
                  // IconTile(
                  //   label: 'Get Started',
                  //   iconName: 'rocket',
                  //   onTap: () {},
                  // ),
                  IconTile(
                    iconName: 'notification',
                    label: 'Notifications',
                    highlight: section == HomeSection.notifications,
                    onTap: () async {
                      // File browsers track their own selected states.
                      // so you have to tell them specifically that stuff not selected
                      rive.activeFileBrowser.value?.openFolder(null, false);
                      await rive.setActiveFileBrowser(null);
                      rive.sectionListener.value = HomeSection.notifications;
                    },
                  ),
                  // Not currently implemented
                  // IconTile(
                  //   iconName: 'recents',
                  //   label: 'Recents',
                  //   onTap: () {},
                  // ),
                  // IconTile(
                  //   iconName: 'community-small',
                  //   label: 'Community',
                  //   onTap: () {},
                  // ),
                ],
              ),
            ),
          ),
          Separator(
            color: riveColors.fileLineGrey,
            padding: const EdgeInsets.only(top: 10),
          ),
          Expanded(
            child: ValueListenableBuilder<List<FolderTreeController>>(
              valueListenable: RiveContext.of(context).folderTreeControllers,
              builder: (context, folderTreeControllers, _) {
                var slivers = <Widget>[];
                if (folderTreeControllers != null) {
                  for (int i = 0; i < folderTreeControllers.length; i++) {
                    slivers.add(
                      FolderTreeView(
                        style: treeStyle,
                        controller: folderTreeControllers[i],
                      ),
                    );
                    if (i != folderTreeControllers.length - 1) {
                      slivers.add(
                        SliverToBoxAdapter(
                          child: Separator(
                            color: riveColors.fileLineGrey,
                            padding: EdgeInsets.only(
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
                              icon: 'teams-button',
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
                  scrollController:
                      RiveContext.of(context).treeScrollController,
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

class NavigationPanelStream extends StatefulWidget {
  const NavigationPanelStream({
    Key key,
  }) : super(key: key);

  @override
  _NavigationPanelStreamState createState() => _NavigationPanelStreamState();
}

class _NavigationPanelStreamState extends State<NavigationPanelStream> {
  bool _bottomSliverDocked = false;
  bool get bottomSliverDocked => _bottomSliverDocked;

  set bottomSliverDocked(bool bottomSliverDocked) {
    if (_bottomSliverDocked != bottomSliverDocked) {
      setState(() {
        _bottomSliverDocked = bottomSliverDocked;
      });
    }
  }

  @override
  void initState() {
    // TODO: burn this
    var userManager = UserManager();
    var teamManager = TeamManager();
    var fileManager = FileManager();
    var folderTreeManager = FolderTreeManager();
    userManager.loadMe();
  }

  @override
  Widget build(BuildContext context) {
    var scrollController = RiveContext.of(context).treeScrollController;
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
            child: StreamBuilder<HomeSection>(
              stream: Plumber().getStream<HomeSection>(),
              builder: (context, snapshot) {
                return Column(
                  children: <Widget>[
                    IconTile(
                      iconName: 'notification',
                      label: 'Notifications',
                      highlight: snapshot.data == HomeSection.notifications,
                      onTap: () async {
                        Plumber().message(HomeSection.notifications);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          Separator(
            color: riveColors.fileLineGrey,
            padding: const EdgeInsets.only(top: 10),
          ),
          Expanded(
            child: StreamBuilder<List<BehaviorSubject<FolderTree>>>(
              stream: Plumber().getStream<List<BehaviorSubject<FolderTree>>>(),
              builder: (context, snapshot) {
                var slivers = <Widget>[];
                if (snapshot.data != null) {
                  for (int i = 0; i < snapshot.data.length; i++) {
                    // TODO: rather than folderTree's we prob ably rely on this controller?
                    slivers.add(FolderTreeViewStream(
                        style: treeStyle,
                        controller:
                            FolderTreeItemController(snapshot.data[i].value)));
                    if (i != snapshot.data.length - 1) {
                      slivers.add(
                        SliverToBoxAdapter(
                          child: Separator(
                            color: riveColors.fileLineGrey,
                            padding: EdgeInsets.only(
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
                              icon: 'teams-button',
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
                  scrollController:
                      RiveContext.of(context).treeScrollController,
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
