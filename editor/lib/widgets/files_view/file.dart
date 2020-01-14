import 'package:flutter/material.dart';
import 'package:rive_editor/rive/file_browser/file.dart';
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
    return ChangeNotifierProvider<FileItem>(
      create: (_) => file,
      child: Container(
        padding: const EdgeInsets.only(
          left: 10.0,
          right: 10.0,
          bottom: 20.0,
        ),
        child: Consumer<FileItem>(
          builder: (context, file, child) => Material(
            elevation: file.selected ? 8.0 : 0.0,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(25.0),
            shadowColor: Color.fromRGBO(238, 248, 255, 1.0),
            child: GestureDetector(
              onTap: () => file.onSelect(!file.selected),
              child: Container(
                decoration: file.selected
                    ? BoxDecoration(
                        border: Border.all(
                          color: ThemeUtils.selectedBlue,
                          width: 3.5,
                        ),
                        borderRadius: BorderRadius.circular(25.0),
                      )
                    : null,
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
                            if (file?.image != null &&
                                file.image.isNotEmpty) ...[
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
