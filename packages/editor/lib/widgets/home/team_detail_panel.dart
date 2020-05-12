import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/model.dart';

import 'package:rive_api/models/user.dart';
import 'package:rive_api/models/follow.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/plumber.dart';

import 'package:rive_editor/widgets/common/avatar.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_header.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_panel.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:tree_widget/tree_line.dart';
import 'package:tree_widget/tree_style.dart';

const kTreeItemHeight = 35.0;

class TeamDetailPanel extends StatelessWidget {
  final Team team;

  const TeamDetailPanel({Key key, this.team}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final riveColors = theme.colors;
    final textStyles = theme.textStyles;
    final treeStyle = TreeStyle(
      showFirstLine: false,
      padding: const EdgeInsets.only(
        left: 10,
        right: 10,
        bottom: 0,
        top: 5,
      ),
      lineColor: RiveTheme.of(context).colors.lightTreeLines,
      itemHeight: kTreeItemHeight,
    );

    List<Widget> children = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
            EditableAvatar(
              avatarRadius: 15,
              avatarPath: team.avatarUrl,
              changeAvatar: null,
            ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.only(left: 7),
              child: Text(
                team.name,
                style: textStyles.fileGreyTextLarge,
              ),
            ))
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SizedBox(
          height: 1,
          child: TreeLine(
            color: treeStyle.lineColor,
          ),
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: StreamBuilder<List<TeamMember>>(
            stream: Plumber().getStream<List<TeamMember>>(team.hashCode),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView(
                    children: snapshot.data
                        .map((member) => _TeamMember2(teamMember: member))
                        .toList());
              } else {
                return Text('loading...');
              }
            },
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: SizedBox(
          height: 1,
          child: TreeLine(
            color: treeStyle.lineColor,
          ),
        ),
      ),
    ];

    if (canEditTeam(team.permission)) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: FlatIconButton(
          label: 'Edit Members',
          icon: TintedIcon(
            icon: 'teams-button',
            color: RiveTheme.of(context).colors.fileIconColor,
          ),
          tip: const Tip(
            label: 'Invite new members to your team',
            direction: PopupDirection.topToCenter,
            fallbackDirections: [
              PopupDirection.topToCenter,
            ],
          ),
          onTap: () => showSettings(team,
              context: context, initialPanel: SettingsPanel.members),
        ),
      ));
    }

    return Container(
        decoration: BoxDecoration(
          color: riveColors.fileBackgroundLightGrey,
          border: Border(
              right: BorderSide(
            color: riveColors.fileBorder,
          )),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children));
  }
}

class _TeamMember extends StatelessWidget {
  final RiveUser user;

  const _TeamMember({@required this.user, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              child: Avatar(
                iconBuilder: (context) {
                  if (user.avatar != null) {
                    return Image.network(user.avatar);
                  }
                  return TintedIcon(
                      color: colors.commonDarkGrey, icon: 'your-files');
                },
                background: colors.fileBackgroundLightGrey,
              ),
            ),
            const SizedBox(width: 5),
            RichText(
              text: TextSpan(
                style: styles.fileSearchText
                    .copyWith(color: Colors.black, fontWeight: FontWeight.w500),
                children: <TextSpan>[
                  if (user.name != null) TextSpan(text: user.name),
                  if (user.username != null && user.name != null)
                    const TextSpan(text: '  '),
                  if (user.username != null)
                    TextSpan(
                      style: styles.basic.copyWith(color: colors.inactiveText),
                      text: '@${user.username}',
                    ),
                ],
              ),
            ),
            // Adding a follow button here temporarily
            const Spacer(flex: 1),
            FollowUnfollow(user.ownerId),
          ],
        ),
      ),
    );
  }
}

class _TeamMember2 extends StatelessWidget {
  final TeamMember teamMember;

  const _TeamMember2({@required this.teamMember, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              child: Avatar(
                iconBuilder: (context) {
                  if (teamMember.avatarUrl != null) {
                    return Image.network(teamMember.avatarUrl);
                  }
                  return TintedIcon(
                      color: colors.commonDarkGrey, icon: 'your-files');
                },
                background: colors.fileBackgroundLightGrey,
              ),
            ),
            const SizedBox(width: 5),
            RichText(
              text: TextSpan(
                style: styles.fileSearchText
                    .copyWith(color: Colors.black, fontWeight: FontWeight.w500),
                children: <TextSpan>[
                  if (teamMember.name != null) TextSpan(text: teamMember.name),
                  if (teamMember.username != null && teamMember.name != null)
                    const TextSpan(text: '  '),
                  if (teamMember.username != null)
                    TextSpan(
                      style: styles.basic.copyWith(color: colors.inactiveText),
                      text: '@${teamMember.username}',
                    ),
                ],
              ),
            ),
            // Adding a follow button here temporarily
            const Spacer(flex: 1),
            FollowUnfollow(teamMember.ownerId),
          ],
        ),
      ),
    );
  }
}

class FollowUnfollow extends StatelessWidget {
  const FollowUnfollow(this.ownerId);
  final int ownerId;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);

    return StreamBuilder<Iterable<RiveFollowee>>(
        stream: FollowProvider.of(context).followeesStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final following = snapshot.data.any((f) => ownerId == f.ownerId);
            if (following) {
              return TintedIconButton(
                  icon: 'delete',
                  padding: const EdgeInsets.all(0),
                  backgroundHover: Colors.transparent,
                  iconHover: theme.colors.buttonHover,
                  onPress: () {
                    FollowProvider.of(context).unfollowSink.add(ownerId);
                  });
            } else {
              return TintedIconButton(
                  icon: 'tool-create',
                  padding: const EdgeInsets.all(0),
                  backgroundHover: Colors.transparent,
                  iconHover: theme.colors.buttonHover,
                  onPress: () {
                    FollowProvider.of(context).followSink.add(ownerId);
                  });
            }
          } else {
            return Container();
          }
        });
  }
}
