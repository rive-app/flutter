import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/models/user.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/avatar.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/dialog/team_settings/invites.dart';
import 'package:rive_editor/widgets/dialog/team_settings/rounded_section.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

enum TeamRole { member, admin, delete }

class TeamMembers extends StatefulWidget {
  @override
  _TeamMembersState createState() => _TeamMembersState();
}

class _TeamMembersState extends State<TeamMembers> {
  final _inviteQueue = <Invite>[
    const UserInvite(
        RiveUser(ownerId: 0, name: 'Luigi Rosso', username: 'castor')),
    const UserInvite(
        RiveUser(ownerId: 0, name: 'Matt Sullivan', username: 'wolfgang')),
    const EmailInvite('test@email.com'),
  ];

  final _teamMembers = [
    const RiveUser(ownerId: 0, name: null, username: 'nullname'),
    const RiveUser(ownerId: 1, name: 'Null Username', username: null),
    const RiveUser(
        ownerId: 2,
        name: 'Arnold Schwarzenegger',
        username: 'ArnoldSchnitzel',
        avatar: 'https://avatarfiles.alphacoders.com/178/178485.jpg',
        isAdmin: true),
  ];
  // final _inviteSuggestions = <String>["Umberto", "Bertoldo", "Zi'mberto"];
  TeamRole _selectedInviteType = TeamRole.member;

  void _removeInvitee(int index) {
    setState(() {
      _inviteQueue.removeAt(index);
    });
  }

  void _sendInvites() {
    // TODO:
  }

  void _onRoleChanged(TeamRole role) {
    // TODO:
  }

  @override
  Widget build(BuildContext context) {
    final colors = RiveColors();

    // TODO: hook up to real data.
    // final team = widget.team;
    final teamMembers = _teamMembers; // team.members;
    final canInvite = _inviteQueue.isNotEmpty;

    return ListView(padding: const EdgeInsets.all(30), children: [
      RoundedSection(
          contentBuilder: (sectionContext) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        // Collection of invites to send that wraps when the max
                        // width has been filled.
                        Wrap(
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.start,
                            direction: Axis.horizontal,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (int i = 0; i < _inviteQueue.length; i++)
                                UserInviteBox(_inviteQueue[i].name,
                                    onRemove: () => _removeInvitee(i)),
                              /** TODO:
                              ComboBox<String>(
                              value: _inputVal,
                              sizing: ComboSizing.collapsed,
                              typeahead: true,
                              options: _inviteSuggestions,
                              underline: false,
                              valueColor: colors.commonButtonTextColorDark,
                              onInputChanged: _findUserSuggestions,
                              change: (val) {
                                print('Selected $val');
                                setState(() {
                                  _inviteQueue.add()
                                });
                              },
                            ), 
                            */
                            ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  // Team Role selection.
                  SizedBox(
                    height: 30,
                    child: Center(
                      child: ComboBox<TeamRole>(
                        value: _selectedInviteType,
                        change: (type) => setState(() {
                          _selectedInviteType = type;
                        }),
                        alignment: Alignment.topRight,
                        options: TeamRole.values.sublist(0, 2),
                        toLabel: (option) => describeEnum(option).capsFirst,
                        popupWidth: 116,
                        underline: false,
                        valueColor: colors.fileBackgroundDarkGrey,
                        sizing: ComboSizing.content,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  FlatIconButton(
                    label: 'Send Invite',
                    color: canInvite
                        ? colors.commonDarkGrey
                        : colors.commonButtonInactiveGrey,
                    textColor:
                        canInvite ? Colors.white : colors.inactiveButtonText,
                    onTap: canInvite ? _sendInvites : null,
                    radius: 20,
                  )
                ],
              )),
      const SizedBox(height: 20), 
      // Team Members Section.
      Column(children: [
        for (final teamMember in teamMembers)
          _TeamMember(
              name: teamMember.name,
              username: teamMember.username,
              avatarUrl: teamMember.avatar,
              role: teamMember.isAdmin ? TeamRole.admin : TeamRole.member,
              onRoleChanged: _onRoleChanged,
              hasAccepted: false),
      ]),
    ]);
  }
}

class _TeamMember extends StatelessWidget {
  final String name;
  final String username;
  final String avatarUrl;
  final TeamRole role;
  final bool hasAccepted;
  final ValueChanged<TeamRole> onRoleChanged;

  const _TeamMember(
      {this.name,
      this.username,
      this.role,
      this.hasAccepted,
      this.onRoleChanged,
      this.avatarUrl,
      Key key})
      : assert(name != null || username != null,
            'Name AND Username for this user are both null'),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = RiveColors();
    const styles = TextStyles();

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
                  if (avatarUrl != null) {
                    return Image.network(avatarUrl);
                  }
                  return TintedIcon(color: colors.commonDarkGrey, icon: 'user');
                },
                background: colors.fileBackgroundLightGrey,
              ),
            ),
            const SizedBox(width: 5),
            if (name != null) ...[
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: styles.fileSearchText.copyWith(
                        color: Colors.black, fontWeight: FontWeight.w500),
                  )),
              const SizedBox(width: 10)
            ],
            if (username != null)
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    '@$username',
                    overflow: TextOverflow.ellipsis,
                    style: styles.basic.copyWith(color: colors.inactiveText),
                  )),
            const Spacer(),
            if (!hasAccepted)
              Text(
                "Hasn't accepted invite",
                style: styles.tooltipDisclaimer.copyWith(
                    fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
              ),
            const SizedBox(width: 20),
            SizedBox(
              height: 30,
              child: Center(
                child: ComboBox<TeamRole>(
                  value: role,
                  change: onRoleChanged,
                  alignment: Alignment.topRight,
                  options: TeamRole.values,
                  toLabel: (option) => describeEnum(option).capsFirst,
                  popupWidth: 116,
                  underline: false,
                  valueColor: colors.fileBackgroundDarkGrey,
                  sizing: ComboSizing.content,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
