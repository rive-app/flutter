import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/folder.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/theme.dart';

class FolderViewWidget extends StatelessWidget {
  final RiveFolder folder;

  const FolderViewWidget({
    @required this.folder,
    Key key,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final _fileBrowser = Provider.of<FileBrowser>(context, listen: false);
    final _rive = Provider.of<Rive>(context, listen: false);
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
                        color: ThemeUtils.selectedBlue,
                        width: 4.0,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: ThemeUtils.selectedBlue.withOpacity(0.5),
                          blurRadius: 50.0,
                          offset: const Offset(0.0, 10.0),
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
                    color: ThemeUtils.backgroundLightGrey,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: <Widget>[
                        RiveIcons.folder(_isSelected
                            ? ThemeUtils.selectedBlue
                            : ThemeUtils.iconColor),
                        Container(width: 8.0),
                        Expanded(
                          child: Text(
                            folder.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: _isSelected
                                    ? ThemeUtils.selectedBlue
                                    : ThemeUtils.textGrey),
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
