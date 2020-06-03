import 'package:flutter/widgets.dart';
import 'package:rive_api/model.dart';
import 'package:rive_editor/widgets/common/click_listener.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class BrowserFile extends StatelessWidget {
  const BrowserFile(this.file, this.selected, {Key key}) : super(key: key);
  final File file;
  final bool selected;

  Widget _label(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    return Padding(
      padding: const EdgeInsets.all(16),
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
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      child: Container(
        color: colors.fileBackgroundDarkGrey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    return ClickListener(
      onDoubleClick: (_) =>
          RiveContext.of(context).open(file.fileOwnerId, file.id, file.name),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: colors.fileBackgroundLightGrey,
              borderRadius: BorderRadius.circular(12),
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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0x00FFFFFF),
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(
                        color: selected
                            ? colors.fileSelectedBlue
                            : colors.fileBrowserBackground,
                        width: 4,
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
