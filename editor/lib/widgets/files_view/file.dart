import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_core/selectable_item.dart';
import 'package:rive_editor/rive/file_browser/file.dart';
import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:provider/provider.dart';

import '../listenable_builder.dart';

class FileViewWidget extends StatefulWidget {
  final RiveFile file;

  const FileViewWidget({
    Key key,
    @required this.file,
  }) : super(key: key);

  @override
  _FileViewWidgetState createState() => _FileViewWidgetState();
}

class _FileViewWidgetState extends State<FileViewWidget> {
  @override
  void initState() {
    widget.file.needDetails();
    super.initState();
  }

  @override
  void didUpdateWidget(FileViewWidget oldWidget) {
    if (oldWidget.file != widget.file) {
      oldWidget.file.doneWithDetails();
      if (mounted) {
        widget.file.needDetails();
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.file.doneWithDetails();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const kBottomHeight = 40.0;
    final _fileBrowser = Provider.of<FileBrowser>(context, listen: false);
    final _rive = Provider.of<Rive>(context, listen: false);

    return ValueListenableBuilder<SelectionState>(
      valueListenable: widget.file.selectionState,
      child: ListenableBuilder<RiveFile>(
        listenable: widget.file,
        builder: (context, file, _) {
          // print("BUILD $file ${file.name}");
          return Column(
            children: <Widget>[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(5.0),
                      topRight: Radius.circular(5.0),
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
                      if (file.preview != null && file.preview.isNotEmpty) ...[
                        Positioned.fill(
                          child: Image.network(
                            file.preview,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.medium,
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
                    bottomLeft: Radius.circular(5.0),
                    bottomRight: Radius.circular(5.0),
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.only(left: 20.0),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    file.name ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: ThemeUtils.textGrey),
                  ),
                ),
              ),
            ],
          );
        },
      ),
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
                          offset: Offset(0.0, 10.0),
                        ),
                      ]),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                _fileBrowser.selectItem(_rive, widget.file);
              },
              onDoubleTap: () {
                final _rive = Provider.of<Rive>(context, listen: false);
                _fileBrowser.openFile(_rive, widget.file);
              },
              child: child,
            ),
          ],
        );
      },
    );
  }
}
