import 'package:cursor/propagating_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/artists.dart';
import 'package:rive_api/teams.dart';
import 'package:rive_api/models/user.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/models/team_invite_status.dart';
import 'package:rive_core/event.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/avatar.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/dialog/team_settings/user_invite_box.dart';
import 'package:rive_editor/widgets/dialog/team_settings/rounded_section.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/toolbar/connected_users.dart';

class TeamMembers extends StatefulWidget {
  final RiveApi api;
  final Team owner;

  const TeamMembers(this.owner, this.api, {Key key})
      : assert(api != null),
        super(key: key);

  @override
  _TeamMemberState createState() => _TeamMemberState();
}

class _TeamMemberState extends State<TeamMembers> {
  RiveTeamsApi _api;

  @override
  void initState() {
    super.initState();
    _api = RiveTeamsApi(widget.api);
    _updateAffiliates();
  }

  void _updateAffiliates() {
    TeamManager().loadTeamMembers(widget.owner);
  }

  void _onRoleChanged(TeamMember member, String role) {
    // TODO: change team members role
    print('Role changed $member, $role');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(30),
        physics: const ClampingScrollPhysics(),
        children: [
          InvitePanel(
            api: widget.api,
            team: widget.owner,
            teamUpdated: _updateAffiliates,
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<TeamMember>>(
            stream: Plumber()
                .getStream<List<TeamMember>>(widget.owner.hashCode.toString()),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                    children: snapshot.data
                        .map((member) => _TeamMember(
                              user: member,
                              onRoleChanged: (role) =>
                                  _onRoleChanged(member, role),
                            ))
                        .toList());
              } else {
                return const Text('loading...');
              }
            },
          ),
        ]);
  }
}

class InvitePanel extends StatefulWidget {
  final RiveApi api;
  final Team team;
  final VoidCallback teamUpdated;

  const InvitePanel(
      {@required this.api,
      @required this.team,
      @required this.teamUpdated,
      Key key})
      : super(key: key);
  @override
  _InvitePanelState createState() => _InvitePanelState();
}

class _InvitePanelState extends State<InvitePanel> {
  final _inviteQueue = <Invite>[];

  TeamRole _selectedInviteType = TeamRole.member;
  RiveArtists _userApi;
  RiveTeamsApi _teamApi;
  final _openCombo = Event();

  Set<int> get _inviteIds =>
      Set.from(_inviteQueue.whereType<UserInvite>().map<int>((e) => e.ownerId));

  @override
  void initState() {
    super.initState();
    _userApi = RiveArtists(widget.api);
    _teamApi = RiveTeamsApi(widget.api);
  }

  void _sendInvites() {
    _teamApi
        .sendInvites(
      widget.team.ownerId,
      _inviteIds,
      _selectedInviteType,
    )
        .then((value) {
      if (value.isNotEmpty) {
        // TODO: use a more robust check for setState.
        if (mounted) {
          setState(() {
            _inviteQueue.clear();
            widget.teamUpdated();
          });
        }
      }
    });
  }

  void _startTypeahead() {
    _openCombo.notify();
  }

  Future<List<RiveUser>> _autocomplete(String input) {
    final teamMembers = Plumber()
        .getStream<List<TeamMember>>(widget.team.hashCode.toString())
        .value;
    final teamMemberIds = teamMembers.map((e) => e.ownerId);
    final filterIds = _inviteIds..addAll(teamMemberIds);
    return _userApi.autocomplete(input, filterIds);
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
                                (e) => UserInviteBox(
                                  e.name,
                                  onRemove: () {
                                    setState(
                                      () {
                                        _inviteQueue.remove(e);
                                      },
                                    );
                                  },
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: ComboBox<RiveUser>(
                                  trigger: _openCombo,
                                  // Start with an empty value.
                                  value: null,
                                  sizing: ComboSizing.collapsed,
                                  popupSizing: ComboPopupSizing.content,
                                  typeahead: true,
                                  underline: false,
                                  chevron: false,
                                  valueColor: colors.inactiveText,
                                  cursorColor: colors.commonButtonTextColorDark,
                                  valueTextStyle:
                                      RiveTheme.of(context).textStyles.basic,
                                  retriever: _autocomplete,
                                  change: (val) {
                                    setState(() {
                                      _inviteQueue.add(UserInvite(
                                          val.ownerId, val.displayName));
                                      _startTypeahead();
                                    });
                                  },
                                  leadingBuilder: (context, isHovered, item) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: AvatarView(
                                        diameter: 20,
                                        borderWidth: 0,
                                        imageUrl: item.avatar,
                                        name: item.name ?? item.username,
                                        color: Colors.transparent,
                                      ),
                                    );
                                  },
                                  toLabel: (user) {
                                    if (user == null) {
                                      if (_inviteQueue.isNotEmpty) return '';
                                      return 'Invite a member...';
                                    }
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

class _TeamMember extends StatelessWidget {
  final TeamMember user;
  final ValueChanged<String> onRoleChanged;

  const _TeamMember({@required this.user, this.onRoleChanged, Key key})
      : super(key: key);

  String _getRole() {
    switch (user.permission) {
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
      padding: const EdgeInsets.only(bottom: 20),
      child: SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              child: Avatar(
                iconBuilder: (context) {
                  if (user.avatarUrl != null) {
                    return Image.network(user.avatarUrl);
                  }
                  return TintedIcon(
                      color: colors.commonDarkGrey, icon: 'your-files');
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
                  options: TeamRoleExtension.names..add('Delete'),
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
