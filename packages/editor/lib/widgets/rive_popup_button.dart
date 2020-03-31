import 'package:flutter/material.dart';
import 'package:rive_editor/rive/open_file_context.dart';

import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/popup/tip.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

typedef OpenFileWidgetBuilder = Widget Function(BuildContext, OpenFileContext);
typedef OpenFileHoverWidgetBuilder = Widget Function(
    BuildContext, OpenFileContext, bool);

/// Create a widget builder that grabs the Rive context from Provider.
class RiveBuilder extends StatelessWidget {
  final OpenFileWidgetBuilder builder;

  const RiveBuilder({Key key, this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(context, ActiveFile.of(context));
  }
}

/// A button that triggers a popup and gets the current OpenFile context.
class RivePopupButton extends StatefulWidget {
  final List<PopupContextItem> contextItems;
  final OpenFileHoverWidgetBuilder iconBuilder;
  final bool showChevron;
  final PopupOpened<PopupContextItem> opened;
  final double _width;
  final Tip tip;

  const RivePopupButton({
    Key key,
    this.contextItems,
    this.iconBuilder,
    this.showChevron = true,
    this.opened,
    double width,
    this.tip,
  })  : _width = width ?? 177,
        super(key: key);

  @override
  _RivePopupButtonState createState() => _RivePopupButtonState();
}

class _RivePopupButtonState extends State<RivePopupButton> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return RiveBuilder(
      builder: (context, rive) => PopupButton<PopupContextItem>(
        opened: widget.opened,
        items: widget.contextItems,
        width: widget._width,
        arrowTweak: widget.showChevron ? const Offset(-5, 0) : Offset.zero,
        tip: widget.tip,
        builder: (context) => MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Container(
            padding:
                EdgeInsets.only(left: 10, right: widget.showChevron ? 5 : 10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? RiveTheme.of(context).colors.toolbarButtonBackGroundHover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: widget.showChevron
                  ? Row(
                      children: [
                        widget.iconBuilder(context, rive, _isHovered),
                        TintedIcon(
                          color: RiveTheme.of(context).colors.toolbarButton,
                          icon: 'dropdown',
                        ),
                      ],
                    )
                  : widget.iconBuilder(context, rive, _isHovered),
            ),
          ),
        ),
        itemBuilder: (context, item, isHovered) => item.itemBuilder(
          context,
          isHovered,
        ),
      ),
    );
  }
}
