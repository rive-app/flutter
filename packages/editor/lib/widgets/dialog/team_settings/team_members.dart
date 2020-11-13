import 'dart:math';

import 'package:cursor/propagating_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/artists.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/team_invite_status.dart';
import 'package:rive_api/models/team_role.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_api/teams.dart';
import 'package:rive_core/event.dart';
import 'package:rive_editor/rive/stage/items/stage_cursor.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/dialog/team_settings/invite_box.dart';
import 'package:rive_editor/widgets/dialog/team_settings/rounded_section.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
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
  @override
  void initState() {
    super.initState();
    _updateAffiliates();
  }

  void _updateAffiliates() => TeamManager().loadTeamMembers(widget.owner);

  Future<void> _onRoleChanged(TeamMember member, TeamRole role) async {
    final team = widget.owner;
    if (member.status == TeamInviteStatus.pending) {
      await TeamManager().onInviteChanged(team, member, role);
    } else {
      await TeamManager().onRoleChanged(team, member.ownerId, role);
    }
    _updateAffiliates();
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
          ValueStreamBuilder<List<TeamMember>>(
            stream:
                Plumber().getStream<List<TeamMember>>(widget.owner.hashCode),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: snapshot.data
                      .map(
                        (member) => _MemberRow(
                          key: ValueKey<int>((member.ownerId != 0)
                              ? member.ownerId
                              : member.username.hashCode),
                          user: member,
                          onRoleChanged: (role) => _onRoleChanged(member, role),
                        ),
                      )
                      .toList(),
                );
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

  const InvitePanel({
    @required this.api,
    @required this.team,
    @required this.teamUpdated,
    Key key,
  }) : super(key: key);
  @override
  _InvitePanelState createState() => _InvitePanelState();
}

class _InvitePanelState extends State<InvitePanel> {
  final _inviteQueue = <Invite>[];
  // Invites get highlighted when they are ready to be removed
  int _inviteHighlightIndex;
  bool _isTextEmpty = true;
  bool _buttonDisabled = false;

  TeamRole _selectedInviteType = TeamRole.member;
  RiveArtists _userApi;
  RiveTeamsApi _teamApi;
  final _openCombo = Event();

  Set<int> get _userInvites =>
      Set.from(_inviteQueue.whereType<UserInvite>().map<int>((e) => e.ownerId));
  Set<String> get _emailInvites => Set.from(
      _inviteQueue.whereType<EmailInvite>().map<String>((e) => e.email));

  @override
  void initState() {
    super.initState();
    _userApi = RiveArtists(widget.api);
    _teamApi = RiveTeamsApi(widget.api);
  }

  void _sendInvites() {
    if (_buttonDisabled) {
      return;
    }

    setState(() {
      _buttonDisabled = true;
    });
    _teamApi
        .sendInvites(
      widget.team.ownerId,
      _selectedInviteType,
      _userInvites,
      _emailInvites,
    )
        .then(
      (success) {
        if (success) {
          if (mounted) {
            setState(
              () {
                _inviteQueue.clear();
                widget.teamUpdated();
                _buttonDisabled = false;
              },
            );
          }
        }
      },
    );
  }

  void _startTypeahead() {
    _openCombo.notify();
    _isTextEmpty = true;
  }

  void _highlightInvite(bool moveLeft) {
    if (_inviteQueue.isEmpty) {
      return;
    }
    if (moveLeft) {
      setState(() {
        // If the index is null, no invite is highlited:
        // fall back to the last element in the list.
        final index = (_inviteHighlightIndex ?? _inviteQueue.length) - 1;
        _inviteHighlightIndex = max(index, 0);
      });
    } else {
      setState(() {
        // Fallback for null index.
        final index = _inviteHighlightIndex ?? _inviteQueue.length;
        // Moving all the way to the right should remove the invite highlight.
        _inviteHighlightIndex =
            index + 1 >= _inviteQueue.length ? null : index + 1;
      });
    }
  }

  void _onKeyPress(PhysicalKeyboardKey key, String text) {
    if (text.isNotEmpty) {
      _isTextEmpty = false;
      return;
    } else if (!_isTextEmpty) {
      // Flag when text is empty again for the first time.
      _isTextEmpty = true;
      return;
    }

    if (key == PhysicalKeyboardKey.backspace) {
      _removeHighlight();
    } else if (key == PhysicalKeyboardKey.arrowRight) {
      _highlightInvite(false);
    } else if (key == PhysicalKeyboardKey.arrowLeft) {
      _highlightInvite(true);
    }
  }

  void _removeHighlight() {
    if (_inviteQueue.isEmpty) {
      return;
    }
    if (_inviteHighlightIndex != null) {
      setState(() {
        _inviteQueue.removeAt(_inviteHighlightIndex);
        _inviteHighlightIndex = null;
      });
    } else {
      // Before removing anything, highlight it first.
      _highlightInvite(true);
    }
  }

  // From here: https://stackoverflow.com/a/201378
  final _emailRFC5322Regex = RegExp(
      r"""(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9]))\.){3}(?:(2(5[0-5]|[0-4][0-9])|1[0-9][0-9]|[1-9]?[0-9])|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])""");

  bool _isDuplicateEmail(String input) {
    // Search for team members that are email addresses.
    final teamMembers = Plumber().peek<List<TeamMember>>(widget.team.hashCode);
    final emailMembers = teamMembers
        .where((e) => e.name != null && _emailRFC5322Regex.hasMatch(e.name))
        .map((e) => e.name);
    final alreadyInvited = _emailInvites..addAll(emailMembers);
    return alreadyInvited.contains(input);
  }

  Future<List<Invite>> _autocomplete(String input) async {
    if (input.isEmpty) {
      return null;
    }
    // Show email autocomplete.
    if (_emailRFC5322Regex.hasMatch(input) && !_isDuplicateEmail(input)) {
      return [EmailInvite(input)];
    }

    final teamMembers = Plumber().peek<List<TeamMember>>(widget.team.hashCode);
    final teamMemberIds = teamMembers.map((e) => e.ownerId);
    final filterIds = _userInvites..addAll(teamMemberIds);
    final autocompleteUsers = await _userApi.autocomplete(input, filterIds);
    // Show users autocomplete.
    return autocompleteUsers
        .map((user) => UserInvite(
            ownerId: user.ownerId,
            name: user.name,
            username: user.username,
            avatarUrl: user.avatar))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;

    final canInvite = _inviteQueue.isNotEmpty && !_buttonDisabled;
    final highlightedInvite = _inviteHighlightIndex != null
        ? _inviteQueue[_inviteHighlightIndex]
        : null;
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
                        (invite) => InviteBox(
                          invite.inviteBoxLabel,
                          isSelected: invite == highlightedInvite,
                          onRemove: () {
                            setState(
                              () {
                                // Reset highlight.
                                _inviteHighlightIndex = null;
                                _inviteQueue.remove(invite);
                              },
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 7, bottom: 8),
                        child: ComboBox<Invite>(
                          trigger: _openCombo,
                          // Start with an empty value.
                          value: null,
                          sizing: ComboSizing.collapsed,
                          popupSizing: ComboPopupSizing.content,
                          typeahead: true,
                          onKeyPress: _onKeyPress,
                          underline: false,
                          chevron: false,
                          valueColor: colors.inactiveText,
                          cursorColor: colors.commonButtonTextColorDark,
                          valueTextStyle:
                              RiveTheme.of(context).textStyles.basic,
                          retriever: _autocomplete,
                          change: (val) {
                            setState(
                              () {
                                _inviteQueue.add(val);
                                _startTypeahead();
                              },
                            );
                          },
                          leadingBuilder: (context, isHovered, item) =>
                              item.leadingWidget(context),
                          toLabel: (invite) {
                            if (invite == null) {
                              if (_inviteQueue.isNotEmpty) return '';
                              return 'Invite a member...';
                            }
                            return invite.label;
                          },
                        ),
                      ),
                    ],
                  ),
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
                options: TeamRoleExtension.dropdownOptions,
                toLabel: (option) => option.name,
                popupWidth: 116,
                underline: false,
                valueColor: colors.fileBackgroundDarkGrey,
                sizing: ComboSizing.content,
                contentPadding: EdgeInsets.only(bottom: 1),
              ),
            ),
          ),
          const SizedBox(width: 20),
          FlatIconButton(
            label: 'Send Invite',
            color: canInvite
                ? colors.commonDarkGrey
                : colors.commonButtonInactiveGrey,
            textColor: canInvite ? Colors.white : colors.inactiveButtonText,
            onTap: canInvite ? _sendInvites : null,
            radius: 20,
            mainAxisAlignment: MainAxisAlignment.center,
          )
        ],
      ),
    );
  }
}

class _MemberRow extends StatefulWidget {
  final TeamMember user;
  final ValueChanged<TeamRole> onRoleChanged;

  const _MemberRow({@required this.user, this.onRoleChanged, Key key})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _MemberRowState();
}

class _MemberRowState extends State<_MemberRow> {
  TeamRole _currentRole;

  @override
  void initState() {
    super.initState();
    _currentRole = widget.user.permission;
  }

  void _onRoleChanged(TeamRole role) {
    if (role == _currentRole) {
      return;
    }
    setState(() {
      widget.onRoleChanged(role);
      _currentRole = role;
    });
  }

  List<TeamRole> get _dropdownOptions {
    var me = Plumber().peek<Me>();
    var options = TeamRoleExtension.dropdownOptions;
    if (me.ownerId != widget.user.ownerId) {
      options.add(null);
      options.add(TeamRole.delete);
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;
    final user = widget.user;
    print(widget.user);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: SizedBox(
        height: 20,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            AvatarView(
              diameter: 20,
              borderWidth: 0,
              imageUrl: user.avatarUrl,
              name: user.displayName,
              color: StageCursor.colorFromPalette(user.ownerId),
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
                ),
              ),
              const SizedBox(width: 10)
            ],
            if (user.username != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                // Using this column with SizedBox to align the text baselines
                // as they're misbehaving with the @ character.
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      '@${user.username}',
                      overflow: TextOverflow.ellipsis,
                      style: styles.basic.copyWith(color: colors.inactiveText),
                    ),
                  ],
                ),
              ),
            const Spacer(),
            if (user.status == TeamInviteStatus.pending)
              Text(
                "Hasn't accepted invite",
                style: styles.tooltipDisclaimer.copyWith(
                    fontWeight: FontWeight.w300, fontStyle: FontStyle.italic),
              ),
            const SizedBox(width: 20),
            // Using this column with SizedBox to align the text baselines
            // as they're misbehaving with the ComboBox.
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 2),
                if (_currentRole == TeamRole.owner)
                  Row(
                    children: [
                      Text(
                        _currentRole.name,
                        style: theme.textStyles.basic
                            .copyWith(color: colors.fileBackgroundDarkGrey),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                if (_currentRole != TeamRole.owner)
                  ComboBox<TeamRole>(
                    value: _currentRole,
                    change: _onRoleChanged,
                    alignment: Alignment.topRight,
                    options: _dropdownOptions,
                    toLabel: (option) => option?.name ?? '-',
                    popupWidth: 116,
                    underline: false,
                    valueColor: colors.fileBackgroundDarkGrey,
                    sizing: ComboSizing.content,
                    disabled: _currentRole == TeamRole.owner,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
