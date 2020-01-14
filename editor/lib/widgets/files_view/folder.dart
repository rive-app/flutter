import 'package:flutter/material.dart';
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
    return ChangeNotifierProvider.value(
      value: folder,
      child: Container(
        margin: const EdgeInsets.only(
          left: 10.0,
          right: 10.0,
          bottom: 20.0,
        ),
        child: Consumer<FolderItem>(
          builder: (context, folder, child) => Material(
            elevation: folder.selected ? 8.0 : 0.0,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12.0),
            shadowColor: Color.fromRGBO(238, 248, 255, 1.0),
            child: GestureDetector(
              onTap: () => folder.onSelect(!folder.selected),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 150),
                decoration: folder.selected
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
                  child: Container(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Row(
                      children: <Widget>[
                        PathWidget(
                          path: ThemeUtils.folderIcon,
                          nudge: Offset(0.5, 0.5),
                          paint: Paint()
                            ..color = folder.selected
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
                                color: folder.selected
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
        ),
      ),
    );
  }
}
