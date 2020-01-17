import 'package:flutter/material.dart';

class InspectorView extends StatelessWidget {
  final List<Widget> actions;
  final Widget header;

  const InspectorView({
    Key key,
    this.header,
    this.actions,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          header,
          Column(
            children: <Widget>[
              for (var action in actions) ...[
                Container(height: 10.0),
                action,
              ],
            ],
          )
        ],
      ),
    );
  }
}
