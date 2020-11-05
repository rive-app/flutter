import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class BrowserFolder extends StatelessWidget {
  const BrowserFolder(this.folder, this.selected, {Key key}) : super(key: key);

  final Folder folder;
  final bool selected;

  EdgeInsetsGeometry get padding =>
      const EdgeInsets.only(left: 15, top: 12, bottom: 12, right: 15);

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;
    return GestureDetector(
      onDoubleTap: () {
        final plumber = Plumber();
        final currentDirectory = plumber.peek<CurrentDirectory>();
        final nextDirectory = CurrentDirectory(currentDirectory.owner, folder);
        plumber.message<CurrentDirectory>(nextDirectory);
      },
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colors.fileBackgroundLightGrey,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? colors.fileSelectedBlue
                : colors.fileBrowserBackground,
            width: 4,
          ),
        ),
        child: Row(
          children: [
            TintedIcon(
                icon: folder.isTrash ? PackedIcon.trash : PackedIcon.folder,
                color: colors.black30),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 1),
                child: Text(
                  folder.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: styles.greyText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
