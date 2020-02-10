import 'package:flutter/material.dart';

import 'package:rive_core/selectable_item.dart';
import 'package:tree_widget/flat_tree_item.dart';

import 'package:rive_editor/widgets/dialog/rive_dialog.dart';
import 'package:rive_editor/widgets/tree_view/drop_item_background.dart';

Future<T> showRiveSettings<T>(
    {BuildContext context, List<SettingsScreen> screens}) {
  return showRiveDialog(
      context: context,
      builder: (context) {
        return SettingsPanel(screens: screens);
      });
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
  SettingsScreen({this.label, this.child});
  final String label;
  final Widget child;
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

  @override
  Widget build(BuildContext context) {
    Widget _item(SettingsScreen screen, int index) => Padding(
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          width: 215,
          color: const Color.fromRGBO(241, 241, 241, 1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              for (int i = 0; i < widget.screens.length; i++)
                _item(widget.screens[i], i)
            ],
          ),
        ),
        widget.screens[_selectedIndex].child,
      ],
    );
  }
}
