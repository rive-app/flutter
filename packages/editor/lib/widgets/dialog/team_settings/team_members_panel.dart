import 'package:core/debounce.dart';
import 'package:cursor/propagating_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/artists.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_api/models/user.dart';
import 'package:rive_api/teams.dart';
import 'package:rive_core/event.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/avatar.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/dialog/team_settings/invites.dart';
import 'package:rive_editor/widgets/dialog/team_settings/rounded_section.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class TeamMembers extends StatefulWidget {
  final RiveApi api;
  final RiveTeam owner;

  const TeamMembers(this.owner, this.api, {Key key})
      : assert(api != null),
        super(key: key);

  @override
  _TeamMemberState createState() => _TeamMemberState();
}

class _TeamMemberState extends State<TeamMembers> {
  final _teamMembers = <RiveUser>[
    // Test data.
    // const RiveUser(ownerId: 0, name: null, username: 'nullname'),
    // const RiveUser(ownerId: 1, name: 'Null Username', username: null),
    // const RiveUser(
    //     ownerId: 2,
    //     name: 'Arnold Schwarzenegger',
    //     username: 'ArnoldSchnitzel',
    //     avatar: 'https://avatarfiles.alphacoders.com/178/178485.jpg',
    //     isAdmin: true),
  ];
  RiveTeamsApi _api;

  @override
  void initState() {
    super.initState();
    _api = RiveTeamsApi(widget.api);
    final teamId = widget.owner.ownerId;

    _api.getAffiliates(teamId).then((users) {
      setState(() {
        _teamMembers
          ..clear()
          ..addAll(users);
      });
    });
  }

  void _onRoleChanged(RiveUser user, String role) {
    // TODO:
    // _teamsApi.roleChanged(user.ownerId).then();
    print('Role changed $user, $role');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(30), children: [
      InvitePanel(api: widget.api),
      const SizedBox(height: 20),
      // Team Members Section.
      Column(children: [
        for (final teamMember in _teamMembers)
          _TeamMember(
            user: teamMember,
            onRoleChanged: (role) => _onRoleChanged(teamMember, role),
          ),
      ]),
    ]);
  }
}

class InvitePanel extends StatefulWidget {
  final RiveApi api;

  const InvitePanel({@required this.api, Key key}) : super(key: key);
  @override
  _InvitePanelState createState() => _InvitePanelState();
}

class _InvitePanelState extends State<InvitePanel> {
  final _inviteQueue = <Invite>[
    const UserInvite(
        RiveUser(ownerId: 0, name: 'Luigi Rosso', username: 'castor')),
    const UserInvite(
        RiveUser(ownerId: 0, name: 'Matt Sullivan', username: 'wolfgang')),
    const EmailInvite('test@email.com'),
  ];

  // final _inviteSuggestions = <String>["Umberto", "Bertoldo", "Zi'mberto"];
  TeamRole _selectedInviteType = TeamRole.member;
  RiveArtists _api;
  final _openCombo = Event();

  @override
  void initState() {
    super.initState();
    _api = RiveArtists(widget.api);
  }

  void _sendInvites() {
    // TODO:
  }

  void _startTypeahead() {
    _openCombo.notify();
  }

  Future<List<RiveUser>> _autocomplete(String input) =>
      _api.autocomplete(input);

  @override
  void dispose() {
    cancelDebounce(_startTypeahead);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;

    final canInvite = _inviteQueue.isNotEmpty;

    return RoundedSection(
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
                      PropagatingListener(
                        behavior: HitTestBehavior.translucent,
                        onPointerDown: (_) => _startTypeahead(),
                        child: Wrap(
                            alignment: WrapAlignment.start,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            direction: Axis.horizontal,
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ..._inviteQueue.map(
                                  (e) => UserInviteBox(e.name, onRemove: () {
                                        setState(() {
                                          _inviteQueue.remove(e);
                                        });
                                      })),
                              ComboBox<RiveUser>(
                                trigger: _openCombo,
                                // Start with an empty value.
                                value: null,
                                sizing: ComboSizing.collapsed,
                                popupSizing: ComboPopupSizing.content,
                                typeahead: true,
                                underline: false,
                                chevron: false,
                                valueColor: colors.commonButtonTextColorDark,
                                cursorColor: colors.commonButtonTextColorDark,
                                retriever: _autocomplete,
                                change: (val) {
                                  print("Change $val");
                                  setState(() {
                                    _inviteQueue.add(UserInvite(val));
                                    debounce(_startTypeahead);
                                  });
                                },
                                toLabel: (user) {
                                  var label = '';
                                  if (user.name != null) {
                                    label = '${user.name} ';
                                  }
                                  if (user.username != null) {
                                    label += '@${user.username}';
                                  }
                                  return label;
                                },
                              ),
                            ]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                const Spacer(),
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
                      options: TeamRole.values,
                      toLabel: (option) => option.name,
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
            ));
  }
}

extension TeamRoleOptions on TeamRole {
  static List<String> get names =>
      TeamRole.values.map((e) => describeEnum(e).capsFirst).toList();

  String get name => describeEnum(this).capsFirst;
}

class _TeamMember extends StatelessWidget {
  final RiveUser user;
  final ValueChanged<String> onRoleChanged;

  const _TeamMember({@required this.user, this.onRoleChanged, Key key})
      : super(key: key);

  String _getRole() {
    switch (user.role) {
      case TeamRole.admin:
        return describeEnum(TeamRole.admin).capsFirst;
      default:
        return describeEnum(TeamRole.member).capsFirst;
    }
  }

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
            if (user.name != null) ...[
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    user.name,
                    overflow: TextOverflow.ellipsis,
                    style: styles.fileSearchText.copyWith(
                        color: Colors.black, fontWeight: FontWeight.w500),
                  )),
              const SizedBox(width: 10)
            ],
            if (user.username != null)
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    '@${user.username}',
                    overflow: TextOverflow.ellipsis,
                    style: styles.basic.copyWith(color: colors.inactiveText),
                  )),
            const Spacer(),
            if (user.status == TeamInviteStatus.pending)
              Text(
                "Hasn't accepted invite",
                style: styles.tooltipDisclaimer.copyWith(
                    fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
              ),
            const SizedBox(width: 20),
            SizedBox(
              height: 30,
              child: Center(
                child: ComboBox<String>(
                  value: _getRole(),
                  change: onRoleChanged,
                  alignment: Alignment.topRight,
                  options: TeamRoleOptions.names..add('Delete'),
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
