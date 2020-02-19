import 'package:flutter/material.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

typedef RiveWidgetBuilder = Widget Function(BuildContext, Rive);
typedef RiveHoverWidgetBuilder = Widget Function(BuildContext, Rive, bool);

/// Create a widget builder that grabs the Rive context from Provider.
class RiveBuilder extends StatelessWidget {
  final RiveWidgetBuilder builder;

  const RiveBuilder({Key key, this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return builder(context, RiveContext.of(context));
  }
}

/// A button that triggers a popup and gets the current Rive context.
class RivePopupButton extends StatefulWidget {
  final List<PopupContextItem<Rive>> contextItems;
  final RiveHoverWidgetBuilder iconBuilder;
  final bool showChevron;
  final PopupOpened<Rive, PopupContextItem<Rive>> opened;

  const RivePopupButton({
    Key key,
    this.contextItems,
    this.iconBuilder,
    this.showChevron = true,
    this.opened,
  }) : super(key: key);

  @override
  _RivePopupButtonState createState() => _RivePopupButtonState();
}

class _RivePopupButtonState extends State<RivePopupButton> {
  bool _isHovered = false;
  @override
  Widget build(BuildContext context) {
    return RiveBuilder(
      builder: (context, rive) => PopupButton<Rive, PopupContextItem<Rive>>(
        opened: widget.opened,
        selectArg: rive,
        items: widget.contextItems,
        builder: (context) => MouseRegion(
          onEnter: (_) {
            setState(() {
              _isHovered = true;
            });
          },
          onExit: (_) {
            setState(() {
              _isHovered = false;
            });
          },
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
