import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/dialog/rive_dialog.dart';
import 'package:rive_editor/widgets/dialog/team_settings/team_settings_header.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:tree_widget/flat_tree_item.dart';

const double settingsTabNavWidth = 215;

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
  final Widget contents;

  const SettingsScreen(this.label, this.contents);
}

class SettingsPanel extends StatefulWidget {
  final bool isTeam;
  final List<SettingsScreen> screens;

  const SettingsPanel({@required this.screens, @required this.isTeam});

  @override
  _SettingsPanelState createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  int _selectedIndex;

  @override
  void initState() {
    _selectedIndex = 0;
    super.initState();
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
    return Container(
      padding: const EdgeInsets.all(20),
      width: settingsTabNavWidth,
      color: background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          for (int i = 0; i < screens.length; i++) _label(screens[i], i)
        ],
      ),
    );
  }

  Widget _contents(Color separator, Widget contents) {
    var minWidth = riveDialogMinWidth;
    var maxWidth = riveDialogMaxWidth;
    if (widget.isTeam) {
      minWidth -= settingsTabNavWidth; // 85.
      maxWidth -= settingsTabNavWidth; // 665.
    }
    return ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth,
          maxWidth: maxWidth,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TeamSettingsHeader(),
            Separator(color: separator),
            Expanded(child: contents),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final screens = widget.screens;
    final colors = RiveTheme.of(context).colors;
    final currentScreen = screens[_selectedIndex];

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isTeam) _nav(screens, colors.fileBackgroundLightGrey),
        _contents(colors.fileLineGrey, currentScreen.contents),
      ],
    );
  }
}
