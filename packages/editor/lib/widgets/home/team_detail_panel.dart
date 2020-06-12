import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/model.dart';

import 'package:rive_api/models/follow.dart';
import 'package:rive_api/models/team_invite_status.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';

import 'package:rive_editor/widgets/common/tinted_icon_button.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_panel.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/toolbar/connected_users.dart';
import 'package:utilities/list.dart';

const kTreeItemHeight = 35.0;

class TeamDetailPanel extends StatelessWidget {
  final Team team;

  const TeamDetailPanel({Key key, this.team}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final riveColors = theme.colors;
    final textStyles = theme.textStyles;

    return Container(
      decoration: BoxDecoration(
        color: riveColors.fileBackgroundLightGrey,
        border: Border(
            right: BorderSide(
          color: riveColors.fileBorder,
        )),
      ),
      padding: const EdgeInsets.all(20),
      child: ValueStreamBuilder<List<TeamMember>>(
        stream: Plumber().getStream<List<TeamMember>>(team.hashCode),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            var members = snapshot.data
                .where((element) => element.status == TeamInviteStatus.accepted)
                .toList();

            var memberCountWidget = Container(
              // color: Colors.yellow,
              height: 35,
              margin: const EdgeInsetsDirectional.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      child: Text(
                    '${members.length} '
                    '${members.pluralize('Member', 'Members')}',
                    style: textStyles.fileLightGreyText,
                    textAlign: TextAlign.start,
                  )),
                  if (canEditTeam(team.permission))
                    TintedIconButton(
                      // padding: EdgeInsets.zero,
                      icon: PackedIcon.add,
                      onPress: () => showSettings(team,
                          context: context,
                          initialPanel: SettingsPanel.members),
                    ),
                ],
              ),
            );

            var memberListWidget = members
                .map((member) => _TeamMember(teamMember: member))
                .toList();
            return ListView(
              children: [memberCountWidget, ...memberListWidget],
            );
          } else {
            return const Text('loading...');
          }
        },
      ),
    );
  }
}

class _TeamMember extends StatelessWidget {
  final TeamMember teamMember;

  const _TeamMember({@required this.teamMember, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            AvatarView(
              diameter: 20,
              borderWidth: 0,
              padding: 0,
              imageUrl: teamMember.avatarUrl,
              name: teamMember.displayName,
              color: StageCursor.colorFromPalette(teamMember.ownerId),
            ),
            const SizedBox(width: 5),
            Text(
              teamMember.name ?? teamMember.username,
              style: styles.fileSearchTextBold,
            ),
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
                  icon: PackedIcon.delete,
                  padding: const EdgeInsets.all(0),
                  backgroundHover: Colors.transparent,
                  iconHover: theme.colors.buttonHover,
                  onPress: () {
                    FollowProvider.of(context).unfollowSink.add(ownerId);
                  });
            } else {
              return TintedIconButton(
                  icon: PackedIcon.toolCreate,
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
