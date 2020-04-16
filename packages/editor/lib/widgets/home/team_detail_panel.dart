import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_api/models/user.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/widgets/common/avatar.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_header.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_panel.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:tree_widget/tree_line.dart';
import 'package:tree_widget/tree_style.dart';

class TeamDetailPanel extends StatelessWidget {
  final RiveTeam team;

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
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: <Widget>[
                    EditableAvatar(
                      avatarRadius: 15,
                      avatarPath: team.avatar,
                      changeAvatar: null,
                    ),
                    Expanded(
                        child: Padding(
                      padding: const EdgeInsets.only(left: 7.0),
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
                  child: ListView(
                      children: team.teamMembers
                          .map((member) => _TeamMember(user: member))
                          .toList()),
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
              Padding(
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
                  onTap: () => showSettings(
                      context: context, initialPanel: SettingsPanel.members),
                ),
              ),
            ]));
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
                  return TintedIcon(color: colors.commonDarkGrey, icon: 'user');
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
            )
          ],
        ),
      ),
    );
  }
}
