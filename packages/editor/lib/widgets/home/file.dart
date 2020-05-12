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

  // If we have a border, there's a 4 pixel deta.
  double get paddingDelta => _isHovered ? 4 : 0;

  Widget get _label {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        bottom: 16 - paddingDelta,
        right: 16 - paddingDelta,
        left: 16 - paddingDelta,
      ),
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
        print("let's open file: $file");
        RiveContext.of(context).open(file.fileOwnerId, file.id, file.name);
      },
      child: MouseRegion(
        onEnter: (_) => setHover(true),
        onExit: (_) => setHover(false),
        child: Container(
          decoration: BoxDecoration(
            color: colors.fileBackgroundLightGrey,
            borderRadius: BorderRadius.circular(10),
            border: _isHovered
                ? Border.all(
                    color: colors.fileSelectedBlue,
                    width: 4,
                  )
                : null,
          ),
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
