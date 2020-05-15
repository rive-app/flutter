import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class BrowserFolder extends StatefulWidget {
  const BrowserFolder(this.folderName, this.folderId, {Key key})
      : super(key: key);

  final String folderName;
  final int folderId;

  @override
  State<StatefulWidget> createState() => _FolderState();
}

class _FolderState extends State<BrowserFolder> {
  bool _isHovered = false;
  bool _isSelected = false; // TODO:

  void setHover(bool val) {
    if (val != _isHovered) {
      setState(() {
        _isHovered = val;
      });
    }
  }

  EdgeInsetsGeometry get padding =>
      const EdgeInsets.only(left: 15, top: 17, bottom: 18, right: 15);

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;
    return GestureDetector(
      /** TODO: select
       *  onTap:  ,*/
      onDoubleTap: () {
        final plumber = Plumber();
        final currentDirectory = plumber.peek<CurrentDirectory>();
        final nextDirectory =
            CurrentDirectory(currentDirectory.owner, widget.folderId);
        plumber.message<CurrentDirectory>(nextDirectory);
      },
      child: MouseRegion(
        onEnter: (_) => setHover(true),
        onExit: (_) => setHover(false),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
              color: colors.fileBackgroundLightGrey,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered ? colors.fileSelectedBlue : Colors.white,
                width: 4,
              )),
          child: Row(
            children: [
              TintedIcon(
                  icon: (widget.folderId == 0) ? 'trash' : 'folder',
                  color: colors.black30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.folderName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.greyText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
