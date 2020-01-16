import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/folder.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/path_widget.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:provider/provider.dart';

class FolderViewWidget extends StatelessWidget {
  final FolderItem folder;

  const FolderViewWidget({
    Key key,
    @required this.folder,
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
          children: <Widget>[
            Visibility(
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
                        offset: Offset(0.0, 10.0),
                      ),
                    ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: GestureDetector(
                onTap: () {
                  _fileBrowser.selectFolder(_rive, folder);
                },
                onDoubleTap: () {
                  // _fileBrowser.selectFolder(_rive, folder);
                  _fileBrowser.openFolder(folder);
                },
                child: Container(
                  child: Container(
                    decoration: BoxDecoration(
                      color: ThemeUtils.backgroundLightGrey,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Row(
                        children: <Widget>[
                          PathWidget(
                            path: ThemeUtils.folderIcon,
                            nudge: Offset(0.5, 0.5),
                            paint: Paint()
                              ..color = _isSelected
                                  ? ThemeUtils.selectedBlue
                                  : ThemeUtils.iconColor
                              ..style = PaintingStyle.stroke
                              ..isAntiAlias = true,
                          ),
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
            ),
          ],
        );
      },
    );
  }
}
