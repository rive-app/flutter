import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/folder.dart';
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
    return ValueListenableBuilder<SelectionState>(
      valueListenable: folder.selectionState,
      builder: (context, state, child) {
        final _isSelected = state == SelectionState.selected;
        return Container(
          margin: const EdgeInsets.only(
            left: 10.0,
            right: 10.0,
            bottom: 20.0,
          ),
          child: Container(
            // elevation: _isSelected ? 8.0 : 0.0,
            // shadowColor: Color.fromRGBO(238, 248, 255, 1.0),
            decoration: !_isSelected
                ? null
                : BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                        BoxShadow(
                          color: Colors.blue[50],
                          blurRadius: 18.0,
                          spreadRadius: 5.0,
                          offset: Offset(0.0, 15.0),
                        ),
                      ]),

            child: GestureDetector(
              onTap: () {
                _fileBrowser.selectFolder(folder, !_isSelected);
              },
              onDoubleTap: () {
                _fileBrowser.selectFolder(folder, true);
                _fileBrowser.openFolder(folder);
              },
              child: Container(
                decoration: _isSelected
                    ? BoxDecoration(
                        border: Border.all(
                          color: ThemeUtils.selectedBlue,
                          width: 3.5,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      )
                    : null,
                child: Material(
                  color: ThemeUtils.backgroundLightGrey,
                  borderRadius: BorderRadius.circular(10.0),
                  clipBehavior: Clip.antiAlias,
                  animationDuration: Duration.zero,
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
        );
      },
    );
  }
}
