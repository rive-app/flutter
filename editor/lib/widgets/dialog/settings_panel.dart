import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:tree_widget/flat_tree_item.dart';
import '../tree_view/drop_item_background.dart';

class _SettingsTabItem<T> extends StatelessWidget {
  final String label;
  final T type;
  final bool isSelected;
  final VoidCallback onSelect;

  const _SettingsTabItem(
      {Key key, this.label, this.type, this.isSelected = false, this.onSelect})
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

abstract class SettingsPanel<T> extends StatefulWidget {
  final List<T> contents;

  const SettingsPanel({Key key, this.contents}) : super(key: key);
  Widget buildSettingsPage(BuildContext context, T type);

  String label(T type);

  @override
  _SettingsPanelState<T> createState() => _SettingsPanelState<T>();
}

class _SettingsPanelState<T> extends State<SettingsPanel<T>> {
  T _selectedItem;

  @override
  void initState() {
    _selectedItem = widget.contents.first;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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
            children: widget.contents
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _SettingsTabItem(
                      onSelect: () {
                        setState(() {
                          _selectedItem = item;
                        });
                      },
                      label: widget.label(item),
                      type: item,
                      isSelected: item == _selectedItem,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ),
        widget.buildSettingsPage(context, _selectedItem),
      ],
    );
  }
}
