import 'package:flutter/material.dart';

import 'package:rive_editor/widgets/inherited_widgets.dart' show RiveTheme;
import 'package:rive_editor/widgets/tinted_icon.dart';

class IconTile extends StatelessWidget {
  const IconTile({
    @required this.label,
    @required this.iconName,
    this.onTap,
    this.highlight = false,
    Key key,
  }) : super(key: key);

  final String label;
  final bool highlight;
  final VoidCallback onTap;
  final String iconName;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final highlightTextStyle = theme.textStyles.fileWhiteText;
    final highlightIconColor = theme.colors.fileSelectedFolderIcon;
    final unhighlightTextStyle = theme.textStyles.fileLightGreyText;
    final unhighlightIconColor = theme.colors.fileIconColor;
    final highlightDecoration = BoxDecoration(
      color: theme.colors.toolbarButtonSelected,
      borderRadius: const BorderRadius.all(
        Radius.circular(5),
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: highlight ? highlightDecoration : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 10,
          ),
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 15,
                height: 15,
                child: TintedIcon(
                  color: highlight ? highlightIconColor : unhighlightIconColor,
                  icon: iconName,
                ),
              ),
              Container(width: 5),
              Text(
                label,
                style: highlight ? highlightTextStyle : unhighlightTextStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
