import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/popup/popup.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

typedef RiveWidgetBuilder = Widget Function(BuildContext, Rive);

/// Create a widget builder that grabs the Rive context from Provider.
class RiveBuilder extends StatelessWidget {
  final RiveWidgetBuilder builder;

  const RiveBuilder({Key key, this.builder}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<Rive>(
      builder: (context, rive, _) => builder(context, rive),
    );
  }
}

/// A button that triggers a popup and gets the current Rive context.
class RivePopupButton extends StatefulWidget {
  final List<PopupContextItem<Rive>> contextItems;
  final RiveWidgetBuilder iconBuilder;
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
              // TODO: move to theme file
              color: _isHovered
                  ? const Color.fromRGBO(68, 68, 68, 1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Center(
              child: widget.showChevron
                  ? Row(
                      children: [
                        widget.iconBuilder(context, rive),
                        const TintedIcon(
                          color: Color.fromRGBO(140, 140, 140, 1),
                          icon: 'dropdown',
                        ),
                      ],
                    )
                  : widget.iconBuilder(context, rive),
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
