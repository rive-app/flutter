import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_api/models/team_invite_status.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_api/teams.dart';
import 'package:rive_editor/platform/load_file.dart';
import 'package:rive_editor/selectable_item.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/dialog/rive_dialog.dart';
import 'package:rive_editor/widgets/dialog/team_settings/billing_history.dart';
import 'package:rive_editor/widgets/dialog/team_settings/plan.dart';
import 'package:rive_editor/widgets/dialog/team_settings/profile_panel.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_header.dart';
import 'package:rive_editor/widgets/dialog/team_settings/team_account.dart';
import 'package:rive_editor/widgets/dialog/team_settings/team_members.dart';
import 'package:rive_editor/widgets/dialog/team_settings/user_account.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:tree_widget/flat_tree_item.dart';

const double settingsTabNavWidth = 215;

enum SettingsPanel { settings, members, plan, history }

/// map to map SettingsPanels to their appropriate indexes.
final Map<SettingsPanel, int> panelMap = {
  SettingsPanel.settings: 0,
  SettingsPanel.members: 1,
  SettingsPanel.plan: 2,
  SettingsPanel.history: 3,
};

RiveApi _getApi(BuildContext ctx) => RiveContext.of(ctx).api;

Future showSettings(
  Owner owner, {
  BuildContext context,
  SettingsPanel initialPanel = SettingsPanel.settings,
}) {
  return showRiveDialog<void>(
      context: context,
      builder: (ctx) {
        final api = _getApi(ctx);
        if (owner is RiveTeam) {
          RiveTeamsApi(api).getAffiliates(owner.ownerId);
        }
        return Settings(api: api, owner: owner, initialPanel: initialPanel);
      });
}

class Settings extends StatefulWidget {
  final Owner owner;
  final RiveApi api;
  final SettingsPanel initialPanel;
  const Settings(
      {@required this.api, @required this.owner, Key key, this.initialPanel})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsState(initialPanel);
}

class _SettingsState extends State<Settings> {
  _SettingsState(SettingsPanel initalPanel) {
    _selectedIndex = panelMap[initalPanel];
  }
  int _selectedIndex;
  String newAvatarPath;
  bool avatarUploading = false;

  bool get isTeam => widget.owner is Team;
  Team get team => isTeam ? widget.owner as Team : null;

  Widget _panel(Widget child) {
    return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: riveDialogMaxWidth),
        child: child);
  }

  Widget _label(SettingsScreen screen, int index) => _SettingsTabItem(
        onSelect: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        label: screen.label,
        isSelected: index == _selectedIndex,
      );

  Future<void> changeAvatar() async {
    Uint8List data = await LoadFile.getUserFile(['png']);

    if (data != null) {
      String remoteAvatarPath;
      setState(() {
        avatarUploading = true;
      });

      try {
        if (isTeam) {
          remoteAvatarPath = await RiveTeamsApi(widget.api)
              .uploadAvatar(widget.owner.ownerId, data);
        } else {
          remoteAvatarPath = await MeApi(widget.api).uploadAvatar(data);
        }
      } finally {
        setState(() {
          avatarUploading = false;
          if (remoteAvatarPath != null) {
            newAvatarPath = remoteAvatarPath;
            if (isTeam) {
              TeamManager().loadTeams();
            } else {
              UserManager().updateAvatar(remoteAvatarPath);
            }
          }
        });
      }
    }
  }

  Widget _nav(List<SettingsScreen> screens, Color background) {
    var i = 0;
    return Container(
      padding: const EdgeInsets.all(20),
      width: settingsTabNavWidth,
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [...screens.map((e) => _label(e, i++))],
      ),
    );
  }

  Widget _contents(Widget child) {
    var minWidth = riveDialogMinWidth - settingsTabNavWidth;
    var maxWidth = riveDialogMaxWidth - settingsTabNavWidth;
    return ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          maxWidth: maxWidth,
        ),
        child: child);
  }

  int get teamMemberCount {
    if (widget.owner is Team) {
      final teamMembers = Plumber().peek<List<TeamMember>>(team.hashCode);
      return teamMembers
          .where((element) => element.status == TeamInviteStatus.accepted)
          .length;
    }
    return 0;
  }

  int get teamMemberPaidCount {
    if (widget.owner is Team) {
      final teamMembers = Plumber().peek<List<TeamMember>>(team.hashCode);
      return teamMembers
          .where((element) => element.status == TeamInviteStatus.accepted)
          .where((element) => !element.free)
          .length;
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final screens = SettingsScreen.getScreens(widget.owner);

    return _panel(
      Row(
        children: [
          _nav(screens, colors.fileBackgroundLightGrey),
          _contents(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SettingsHeader(
                  name: widget.owner.displayName,
                  avatarUploading: avatarUploading,
                  avatarPath: (newAvatarPath == null)
                      ? widget.owner.avatarUrl
                      : newAvatarPath,
                  changeAvatar: changeAvatar,
                  teamMemberCount: teamMemberCount,
                  teamMemberPaidCount: teamMemberPaidCount,
                  isTeam: widget.owner is Team,
                ),
                Separator(color: colors.fileLineGrey),
                Expanded(child: screens[_selectedIndex].builder(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTabItem extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelect;

  const _SettingsTabItem(
      {Key key, this.label, this.isSelected = false, this.onSelect})
      : super(key: key);

  @override
  _TabItemState createState() => _TabItemState();
}

class _TabItemState extends State<_SettingsTabItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    SelectionState state;
    Color tabColor;
    if (widget.isSelected) {
      state = SelectionState.selected;
      tabColor = colors.fileSelectedBlue;
    } else if (_isHovered) {
      state = SelectionState.hovered;
      tabColor = colors.buttonLight;
    } else {
      state = SelectionState.none;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onSelect,
        child: DropItemBackground(
          DropState.none,
          state,
          color: tabColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Roboto-Regular',
                fontSize: 13,
                color: widget.isSelected
                    ? Colors.white
                    : const Color.fromRGBO(102, 102, 102, 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsScreen {
  final String label;
  final WidgetBuilder builder;

  const SettingsScreen(this.label, this.builder);

  static List<SettingsScreen> getScreens(Owner owner) {
    if (owner is Team) {
      return [
        SettingsScreen(
          'Team Settings',
          (ctx) => ProfileSettings(owner),
        ),
        SettingsScreen(
          'Members',
          (ctx) => TeamMembers(
            owner,
            _getApi(ctx),
          ),
        ),
        SettingsScreen(
          'Plan',
          (ctx) => PlanSettings(
            owner,
            _getApi(ctx),
          ),
        ),
        SettingsScreen(
          'Billing History',
          (ctx) => BillingHistory(
            owner,
            _getApi(ctx),
          ),
        ),
        SettingsScreen(
          'Account',
          (ctx) => TeamAccount(team: owner),
        ),
      ];
    } else {
      return [
        SettingsScreen(
          'Profile',
          (ctx) => ProfileSettings(owner),
        ),
        SettingsScreen('Account', (ctx) => UserAccount()
            //   owner,
            //   _getApi(ctx),
            // ),
            ),
      ];
    }
  }
}
