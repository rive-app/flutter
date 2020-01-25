import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/file_browser/rive_file.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/inspector_view.dart';
import 'package:rive_editor/widgets/theme.dart';

class ItemView extends StatelessWidget {
  final SelectableItem item;

  const ItemView({
    Key key,
    @required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InspectorView(
      header: _buildHeader(),
      actions: <Widget>[
        const FlatIconButton(
          label: "Export for Runtime",
        ),
        const FlatIconButton(
          label: "Duplicate",
        ),
        const FlatIconButton(
          label: "Delete",
        ),
        if (item is RiveFile)
          FlatIconButton(
            label: "Open",
            color: Colors.black,
            textColor: Colors.white,
            elevated: true,
          ),
      ],
    );
  }

  Widget _buildHeader() {
    if (item is RiveFile) {
      final _file = item as RiveFile;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _file.name,
            style: TextStyle(
              fontSize: 16,
              color: ThemeUtils.textGrey,
            ),
          ),
          Container(height: 10.0),
          Text(
            'Type a description...',
            style: TextStyle(
              fontSize: 13,
              color: ThemeUtils.backgroundDarkGrey,
            ),
          ),
        ],
      );
    }
    if (item is RiveFolder) {
      final _folder = item as RiveFolder;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _folder.name,
            style: TextStyle(
              fontSize: 16,
              color: ThemeUtils.textGrey,
            ),
          ),
          Container(height: 10.0),
          Text(
            'Type a description...',
            style: TextStyle(
              fontSize: 13,
              color: ThemeUtils.backgroundDarkGrey,
            ),
          ),
        ],
      );
    }
    return Container();
  }
}
