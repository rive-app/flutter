import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:rive_core/selectable_item.dart';

import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/rive_folder.dart';
import 'package:rive_editor/widgets/icons.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class FolderViewWidget extends StatelessWidget {
  final RiveFolder folder;

  const FolderViewWidget({
    @required this.folder,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _fileBrowser = Provider.of<FileBrowser>(context, listen: false);
    final _rive = RiveContext.of(context);
    ;
    return ValueListenableBuilder<SelectionState>(
      valueListenable: folder.selectionState,
      builder: (context, state, child) {
        final _isSelected = state == SelectionState.selected;
        return Stack(
          fit: StackFit.expand,
          overflow: Overflow.visible,
          children: <Widget>[
            Positioned.fill(
              left: -4,
              top: -4,
              bottom: -4,
              right: -4,
              child: Visibility(
                visible: _isSelected,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: RiveTheme.of(context).colors.fileSelectedBlue,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: RiveTheme.of(context)
                              .colors
                              .fileSelectedBlue
                              .withOpacity(0.5),
                          blurRadius: 50,
                          offset: const Offset(0, 10),
                        ),
                      ]),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                _fileBrowser.selectItem(_rive, folder);
              },
              onDoubleTap: () {
                _fileBrowser.openFolder(folder, true);
              },
              child: Container(
                child: Container(
                  decoration: BoxDecoration(
                    color: RiveTheme.of(context).colors.fileBackgroundLightGrey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: <Widget>[
                        FolderIcon(
                            color: _isSelected
                                ? RiveTheme.of(context).colors.fileSelectedBlue
                                : RiveTheme.of(context)
                                    .colors
                                    .fileUnselectedFolderIcon),
                        Container(width: 8),
                        Expanded(
                          child: Text(
                            folder.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _isSelected
                                ? RiveTheme.of(context).textStyles.fileBlueText
                                : RiveTheme.of(context).textStyles.greyText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
