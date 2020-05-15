import 'package:flutter/material.dart';
import 'package:rive_editor/rive/open_file_context.dart';

import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/popup/popup_direction.dart';
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
  final BuildPopupItems<PopupContextItem> contextItemsBuilder;
  final OpenFileHoverWidgetBuilder iconBuilder;
  final bool showChevron;
  final PopupOpened<PopupContextItem> opened;
  final double _width;
  final Tip tip;
  final Offset arrowTweak;
  final PopupDirection direction;
  final double directionPadding;
  final Color hoverColor;

  const RivePopupButton({
    Key key,
    this.contextItemsBuilder,
    this.iconBuilder,
    this.showChevron = true,
    this.arrowTweak,
    this.opened,
    double width,
    this.tip,
    this.direction = PopupDirection.bottomToRight,
    this.directionPadding = 16,
    this.hoverColor,
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
      builder: (context, activeFile) => PopupButton<PopupContextItem>(
        direction: widget.direction,
        directionPadding: widget.directionPadding,
        opened: widget.opened,
        itemsBuilder: widget.contextItemsBuilder,
        width: widget._width,
        arrowTweak: widget.arrowTweak ??
            (widget.showChevron ? const Offset(-5, 0) : Offset.zero),
        tip: widget.tip,
        builder: (context) => MouseRegion(
          onEnter: (_) {
            // If there's a drag operation active, don't show the hover.
            if (activeFile.rive.isDragging) {
              return;
            }
            setState(() => _isHovered = true);
          },
          onExit: (_) => setState(() => _isHovered = false),
          child: Container(
            padding:
                EdgeInsets.only(left: 10, right: widget.showChevron ? 5 : 10),
            decoration: BoxDecoration(
              color: _isHovered
                  ? widget.hoverColor ??
                      RiveTheme.of(context).colors.toolbarButtonBackGroundHover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: widget.showChevron
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      widget.iconBuilder(context, activeFile, _isHovered),
                      TintedIcon(
                        position: TintedIconPosition.round,
                        color: RiveTheme.of(context).colors.toolbarButton,
                        icon: 'dropdown',
                      ),
                    ],
                  )
                : widget.iconBuilder(context, activeFile, _isHovered),
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
