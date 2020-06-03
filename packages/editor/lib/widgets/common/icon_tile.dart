import 'package:flutter/material.dart';
import 'package:rive_editor/packed_icon.dart';

import 'package:rive_editor/widgets/inherited_widgets.dart' show RiveTheme;
import 'package:rive_editor/widgets/tinted_icon.dart';

class IconTile extends StatefulWidget {
  const IconTile({
    @required this.label,
    @required this.icon,
    this.onTap,
    this.highlight = false,
    this.count = 0,
    Key key,
  }) : super(key: key);

  final String label;
  final bool highlight;
  final VoidCallback onTap;
  final Iterable<PackedIcon> icon;

  /// An optional counter to display in the tile
  final int count;

  @override
  _IconTileState createState() => _IconTileState();
}

class _IconTileState extends State<IconTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final highlightTextStyle = theme.textStyles.fileWhiteText;
    final highlightIconColor = theme.colors.fileSelectedFolderIcon;
    final unhighlightTextStyle = theme.textStyles.fileLightGreyText;
    final unhighlightIconColor = theme.colors.fileIconColor;
    final countHighlightTextStyle = theme.textStyles.fileBlueTextLight;
    final countUnhighlightTextStyle = theme.textStyles.fileWhiteText;
    final countHighlightIconColor = theme.colors.toolTipText;
    final countUnhighlightIconColor = theme.colors.accentMagenta;

    final unselectedBackground = _isHovered
        ? theme.colors.fileTreeBackgroundHover
        : theme.colors.fileBackgroundLightGrey;

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: SizedBox(
          height: 35,
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                color: widget.highlight
                    ? theme.colors.toolbarButtonSelected
                    : unselectedBackground,
                borderRadius: const BorderRadius.all(
                  Radius.circular(5),
                ),
              ),
              height: 31,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 10,
                ),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 15,
                      height: 15,
                      child: TintedIcon(
                        color: widget.highlight
                            ? highlightIconColor
                            : unhighlightIconColor,
                        icon: widget.icon,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.label,
                      style: widget.highlight
                          ? highlightTextStyle
                          : unhighlightTextStyle,
                    ),
                    const Spacer(),
                    if (widget.count > 0)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircleAvatar(
                          backgroundColor: widget.highlight
                              ? countHighlightIconColor
                              : countUnhighlightIconColor,
                          child: Text(
                            '${_singleDigitPlus(widget.count)}',
                            style: widget.highlight
                                ? countHighlightTextStyle
                                : countUnhighlightTextStyle,
                          ),
                        ),
                      ),
                    //const SizedBox(width: 7),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Any number over 9 returns as '9+'
String _singleDigitPlus(int num) => num > 9 ? '9+' : '$num';
