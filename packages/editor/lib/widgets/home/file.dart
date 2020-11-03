import 'package:flutter/widgets.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_editor/widgets/common/click_listener.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BrowserFile extends StatefulWidget {
  const BrowserFile(this.file, this.selected, this.suspended, {Key key})
      : super(key: key);
  final File file;
  final bool selected;
  final bool suspended;

  @override
  _BrowserFileState createState() => _BrowserFileState();
}

class _BrowserFileState extends State<BrowserFile> {
  @override
  void initState() {
    super.initState();
    FileManager().needDetails(widget.file);
  }

  @override
  void dispose() {
    super.dispose();
    FileManager().dontNeedDetails(widget.file);
  }

  @override
  void didUpdateWidget(BrowserFile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.id == widget.file.id) {
      return;
    }
    if (oldWidget.file != null) {
      FileManager().dontNeedDetails(oldWidget.file);
    }
    if (widget.file != null) {
      FileManager().needDetails(widget.file);
    }
  }

  Widget _label(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    return Padding(
      padding: const EdgeInsets.only(left: 15, top: 13, bottom: 14),
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

  Widget _screenshot(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;

    final placeholder = Container(
      color: colors.fileBackgroundDarkGrey,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(10),
        topRight: Radius.circular(10),
      ),
      child: (widget.file.thumbnail == null)
          ? placeholder
          : CachedNetworkImage(
              width: double.infinity,
              placeholder: (context, url) => placeholder,
              imageUrl: widget.file.thumbnail,
              fit: BoxFit.cover,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    return ClickListener(
      onDoubleClick: (_) {
        if (!widget.suspended) {
          RiveContext.of(context).open(widget.file);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.fileBackgroundLightGrey,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: widget.selected
                ? colors.fileSelectedBlue
                : colors.fileBrowserBackground,
            width: 4,
          ),
        ),
        child: Container(
          foregroundDecoration: BoxDecoration(
            color: widget.suspended
                ? colors.getTransparent50
                : colors.getTransparent,
            backgroundBlendMode: BlendMode.overlay,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Expanded(
                child: _screenshot(context),
              ),
              _label(context),
            ],
          ),
        ),
      ),
    );
  }
}
