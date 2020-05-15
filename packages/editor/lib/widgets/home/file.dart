import 'package:flutter/widgets.dart';
import 'package:rive_api/model.dart';
import 'package:rive_editor/widgets/common/click_listener.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class BrowserFile extends StatefulWidget {
  const BrowserFile(this.file, {Key key}) : super(key: key);
  final File file;

  @override
  State<StatefulWidget> createState() => _FileState();
}

class _FileState extends State<BrowserFile> {
  bool _isHovered = false;
  bool _isSelected = false; // TODO:

  void setHover(bool val) {
    if (val != _isHovered) {
      setState(() {
        _isHovered = val;
      });
    }
  }

  Widget get _label {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${widget.file.name ?? 'Loading...'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: styles.greyText,
            ),
          ),
        ],
      ),
    );
  }

  // Internal radius looks better with an extra pixel of padding.
  double get radiusDelta => _isHovered ? 5 : 0;

  Widget get _screenshot {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(10 - radiusDelta),
        topRight: Radius.circular(10 - radiusDelta),
      ),
      child: Container(
        // TODO:
        color: colors.fileBackgroundDarkGrey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    return ClickListener(
      /** TODO: Selection 
       * onClick: , */
      onDoubleClick: (_) {
        final file = widget.file;
        RiveContext.of(context).open(file.fileOwnerId, file.id, file.name);
      },
      child: MouseRegion(
        onEnter: (_) => setHover(true),
        onExit: (_) => setHover(false),
        child: Container(
          decoration: BoxDecoration(
              color: colors.fileBackgroundLightGrey,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? colors.fileSelectedBlue
                    : colors.fileBrowserBackground,
                width: 4,
              )),
          child: Column(
            children: [
              Expanded(
                child: _screenshot,
              ),
              _label,
            ],
          ),
        ),
      ),
    );
  }
}
