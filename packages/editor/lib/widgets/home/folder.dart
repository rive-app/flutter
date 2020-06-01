import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class BrowserFolder extends StatelessWidget {
  const BrowserFolder(this.folderName, this.folderId, this.selected, {Key key})
      : super(key: key);

  final String folderName;
  final int folderId;
  final bool selected;

  EdgeInsetsGeometry get padding =>
      const EdgeInsets.only(left: 15, top: 17, bottom: 18, right: 15);

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;
    return GestureDetector(
      onDoubleTap: () {
        final plumber = Plumber();
        final currentDirectory = plumber.peek<CurrentDirectory>();
        final nextDirectory =
            CurrentDirectory(currentDirectory.owner, folderId);
        plumber.message<CurrentDirectory>(nextDirectory);
      },
      child: MouseRegion(
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: colors.fileBackgroundLightGrey,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? colors.fileSelectedBlue : Colors.white,
              width: 4,
            ),
          ),
          child: Row(
            children: [
              TintedIcon(
                  icon: (folderId == 0) ? PackedIcon.trash : PackedIcon.folder,
                  color: colors.black30),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  folderName,
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
