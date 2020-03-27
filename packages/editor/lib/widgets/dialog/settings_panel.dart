import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/dialog/team_settings_header.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';
import 'package:tree_widget/flat_tree_item.dart';

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
  final Widget screen;

  const SettingsScreen(this.label, this.screen);
}

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({@required this.screens});

  final List<SettingsScreen> screens;

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

  @override
  Widget build(BuildContext context) {
    final screens = widget.screens;
    final colors = RiveColors();
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          width: 215,
          color: colors.fileBackgroundLightGrey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (int i = 0; i < screens.length; i++) _label(screens[i], i)
            ],
          ),
        ),
        ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 85,
              maxWidth: 585,
              // maxHeight: 300,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                  child: TeamSettingsHeader(),
                ),
                Separator(color: colors.fileLineGrey),
                Expanded(child: screens[_selectedIndex].screen),
                Separator(color: colors.fileLineGrey),
                Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FlatIconButton(
                          label: 'Save Changes',
                          color: colors.commonDarkGrey,
                          textColor: Colors.white,
                          onTap: () {/* TODO: make sure team info is valid! */},
                        )
                      ],
                    )),
              ],
            ))
      ],
    );
  }
}
