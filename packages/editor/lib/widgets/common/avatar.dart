import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  final WidgetBuilder iconBuilder;
  final Color background;

  const Avatar({@required this.iconBuilder, this.background, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: ColoredBox(
        child: iconBuilder(context),
        color: background ?? Colors.transparent,
      ),
    );
  }
}
