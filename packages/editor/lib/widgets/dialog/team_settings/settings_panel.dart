import 'package:flutter/material.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/models/owner.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_api/teams.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/dialog/rive_dialog.dart';
import 'package:rive_editor/widgets/dialog/team_settings/plan_panel.dart';
import 'package:rive_editor/widgets/dialog/team_settings/profile_panel.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_header.dart';
import 'package:rive_editor/widgets/dialog/team_settings/members_panel.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:tree_widget/flat_tree_item.dart';

const double settingsTabNavWidth = 215;

// Helper functions.
RiveOwner _getOwner(BuildContext ctx) => RiveContext.of(ctx).currentOwner;

RiveApi _getApi(BuildContext ctx) => RiveContext.of(ctx).api;

Future showSettings({BuildContext context}) {
  return showRiveDialog<void>(
      context: context,
      builder: (ctx) {
        final owner = _getOwner(ctx);
        final api = _getApi(ctx);
        if (owner is RiveTeam) {
          RiveTeamsApi(api).getAffiliates(owner.ownerId);
        }
        return Settings(owner: owner);
      });
}

class Settings extends StatefulWidget {
  final RiveOwner owner;
  const Settings({@required this.owner, Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  int _selectedIndex = 0;

  bool get isTeam => widget.owner is RiveTeam;
  RiveTeam get team => isTeam ? widget.owner as RiveTeam : null;

  Widget _panel(Widget child) {
    var maxWidth = riveDialogMaxWidth;

    if (!isTeam) {
      maxWidth -= settingsTabNavWidth;
    }

    return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth), child: child);
  }

  Widget _label(SettingsScreen screen, int index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _SettingsTabItem(
          onSelect: () {
            setState(() {
              _selectedIndex = index;
            });
          },
          label: screen.label,
          isSelected: index == _selectedIndex,
        ),
      );

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

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    final screens = SettingsScreen.getScreens(isTeam);

    return _panel(Row(
      children: [
        if (isTeam) _nav(screens, colors.fileBackgroundLightGrey),
        _contents(Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SettingsHeader(
                name: widget.owner.displayName, teamSize: team?.size ?? -1),
            Separator(color: colors.fileLineGrey),
            Expanded(child: screens[_selectedIndex].builder(context)),
          ],
        )),
      ],
    ));
  }
}

class _SettingsTabItem extends StatelessWidget {
  final String label;

  final bool isSelected;
  final VoidCallback onSelect;

  const _SettingsTabItem(
      {Key key, this.label, this.isSelected = false, this.onSelect})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        height: 31,
        child: DropItemBackground(
          DropState.none,
          isSelected ? SelectionState.selected : SelectionState.none,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 5),
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Roboto-Regular',
                fontSize: 13,
                color: isSelected
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

  static List<SettingsScreen> getScreens(bool isTeam) {
    if (isTeam) {
      return [
        SettingsScreen('Team Settings',
            (ctx) => ProfileSettings(_getOwner(ctx), _getApi(ctx))),
        SettingsScreen('Members',
            (ctx) => TeamMembers(_getOwner(ctx) as RiveTeam, _getApi(ctx))),
        SettingsScreen('Groups', (ctx) => const SizedBox()),
        SettingsScreen('Purchase Permissions', (ctx) => const SizedBox()),
        SettingsScreen('Plan',
            (ctx) => PlanSettings(_getOwner(ctx) as RiveTeam, _getApi(ctx))),
        SettingsScreen('Billing History', (ctx) => const SizedBox()),
      ];
    } else {
      return [
        SettingsScreen(
            'Profile', (ctx) => ProfileSettings(_getOwner(ctx), _getApi(ctx))),
        // SettingsScreen('Store'),
        // SettingsScreen('Billing History'),
      ];
    }
  }
}
