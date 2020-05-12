import 'package:flutter/material.dart';
import 'package:rive_api/model.dart';

import 'package:rive_core/selectable_item.dart';

import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/inspector_view.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class ItemView extends StatelessWidget {
  final SelectableItem item;

  const ItemView({
    Key key,
    @required this.item,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InspectorView(
      header: _buildHeader(context),
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
        if (item is File)
          const FlatIconButton(
            label: "Open",
            color: Colors.black,
            textColor: Colors.white,
            elevation: flatButtonIconElevation,
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (item is File) {
      final _file = item as File;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _file.name,
            style: RiveTheme.of(context).textStyles.fileGreyTextLarge,
          ),
          Container(height: 10.0),
          Text(
            'Type a description...',
            style: RiveTheme.of(context).textStyles.fileLightGreyText,
          ),
        ],
      );
    }
    if (item is Folder) {
      final _folder = item as Folder;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _folder.name,
            style: RiveTheme.of(context).textStyles.fileGreyTextLarge,
          ),
          Container(height: 10.0),
          Text(
            'Type a description...',
            style: RiveTheme.of(context).textStyles.fileLightGreyText,
          ),
        ],
      );
    }
    return Container();
  }
}
