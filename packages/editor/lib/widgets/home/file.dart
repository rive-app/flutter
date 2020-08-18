import 'package:flutter/widgets.dart';
import 'package:rive_api/model.dart';
import 'package:rive_editor/widgets/common/click_listener.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BrowserFile extends StatelessWidget {
  const BrowserFile(this.file, this.selected, this.suspended, {Key key})
      : super(key: key);
  final File file;
  final bool selected;
  final bool suspended;

  Widget _label(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    return Padding(
      padding: const EdgeInsets.only(left: 15, top: 13, bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${file.name ?? 'Loading...'}',
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
      child: (file.thumbnail == null)
          ? placeholder
          : CachedNetworkImage(
              width: double.infinity,
              placeholder: (context, url) => placeholder,
              imageUrl: file.thumbnail,
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
        if (!suspended) {
          RiveContext.of(context).open(file);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: colors.fileBackgroundLightGrey,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected
                ? colors.fileSelectedBlue
                : colors.fileBrowserBackground,
            width: 4,
          ),
        ),
        child: Container(
          foregroundDecoration: BoxDecoration(
            color: suspended ? colors.getTransparent50 : colors.getTransparent,
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
