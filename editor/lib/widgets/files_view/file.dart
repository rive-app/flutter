import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/file_browser/file.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:provider/provider.dart';

class FileViewWidget extends StatelessWidget {
  final FileItem file;

  const FileViewWidget({
    Key key,
    @required this.file,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    const kBottomHeight = 40.0;
    final _fileBrowser = Provider.of<FileBrowser>(context, listen: false);
    return ValueListenableBuilder<SelectionState>(
      valueListenable: file.selectionState,
      child: Column(
        children: <Widget>[
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20.0),
                  topRight: Radius.circular(20.0),
                ),
                color: ThemeUtils.backgroundDarkGrey,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned.fill(
                    child: Image.asset(
                      "assets/images/file_background.png",
                      fit: BoxFit.none,
                      filterQuality: FilterQuality.none,
                    ),
                  ),
                  if (file?.image != null && file.image.isNotEmpty) ...[
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.network(
                          file.image,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Container(
            height: kBottomHeight,
            decoration: BoxDecoration(
              color: ThemeUtils.backgroundLightGrey,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20.0),
                bottomRight: Radius.circular(20.0),
              ),
            ),
            child: Container(
              padding: EdgeInsets.only(left: 20.0),
              alignment: Alignment.centerLeft,
              child: Text(
                file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: ThemeUtils.textGrey),
              ),
            ),
          ),
        ],
      ),
      builder: (context, state, child) {
        final _isSelected = state == SelectionState.selected;
        return Container(
          padding: const EdgeInsets.only(
            left: 10.0,
            right: 10.0,
            bottom: 20.0,
          ),
          child: Container(
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
              onTapDown: (_) {
                _fileBrowser.selectFile(file, !_isSelected);
              },
              onDoubleTap: () {
                _fileBrowser.openFile(file);
              },
              child: Container(
                  decoration: _isSelected
                      ? BoxDecoration(
                          border: Border.all(
                            color: ThemeUtils.selectedBlue,
                            width: 3.5,
                          ),
                          borderRadius: BorderRadius.circular(25.0),
                        )
                      : null,
                  child: child),
            ),
          ),
        );
      },
    );
  }
}
