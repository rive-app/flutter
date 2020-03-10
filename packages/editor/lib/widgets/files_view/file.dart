import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'package:rive_core/selectable_item.dart';

import 'package:rive_editor/rive/file_browser/file_browser.dart';
import 'package:rive_editor/rive/file_browser/rive_file.dart';

import 'package:rive_editor/widgets/common/click_listener.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/listenable_builder.dart';

/// FileView is stateful so that it can track when it's added/removed from
/// widget hierarchy to request batched network details for the file.
class FileViewWidget extends StatefulWidget {
  final RiveFile file;

  const FileViewWidget({
    @required this.file,
    Key key,
  }) : super(key: key);

  @override
  _FileViewWidgetState createState() => _FileViewWidgetState();
}

class _FileViewWidgetState extends State<FileViewWidget> {
  @override
  Widget build(BuildContext context) {
    const double kBottomHeight = 40;
    final _fileBrowser = Provider.of<FileBrowser>(context, listen: false);
    final _rive = RiveContext.of(context);

    return ValueListenableBuilder<SelectionState>(
      valueListenable: widget.file.selectionState,
      child: ListenableBuilder<RiveFile>(
        listenable: widget.file,
        builder: (context, file, _) {
          // Attempt to load the file thumbnail

          var background = Image.asset(
            'assets/images/file_background.png',
            fit: BoxFit.none,
            filterQuality: FilterQuality.none,
          );

          if (file.preview != null && file.preview.isNotEmpty) {
            // TODO: Do some resilient handling of network errors here
            // Commenting out this for the moment to remove network errors
            /*
            background = Image.network(
              file.preview,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
            );
            */
          }

          return Column(
            children: <Widget>[
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(5),
                    ),
                    color: RiveTheme.of(context).colors.fileBackgroundDarkGrey,
                  ),
                  child: Container(
                    constraints: const BoxConstraints.expand(),
                    child: background,
                  ),
                ),
              ),
              Container(
                height: kBottomHeight,
                decoration: BoxDecoration(
                  color: RiveTheme.of(context).colors.fileBackgroundLightGrey,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.only(left: 20),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    file.name ?? "",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: RiveTheme.of(context).textStyles.greyText,
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
                    ],
                  ),
                ),
              ),
            ),
            ClickListener(
              child: child,
              onClick: () {
                _fileBrowser.selectItem(_rive, widget.file);
              },
              onDoubleClick: () {
                _fileBrowser.openFile(_rive, widget.file);
              },
            ),
          ],
        );
      },
    );
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
  void initState() {
    widget.file.needDetails();
    super.initState();
  }
}
