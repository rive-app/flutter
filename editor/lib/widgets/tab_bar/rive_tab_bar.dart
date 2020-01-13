import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_drawing/path_drawing.dart';

import '../path_widget.dart';
import 'tab_decoration.dart';

/// Describes a Rive tab item.
class RiveTabItem {
  final String name;
  final Widget icon;
  final bool closeable;

  RiveTabItem({
    this.name,
    this.icon,
    this.closeable = true,
  });
}

var _closeIcon = parseSvgPathData(
    'M9.68198 8.83883L7.20711 6.36396L9.68198 3.88909C9.87714 3.69393 9.87714 3.37714 9.68198 3.18198C9.48682 2.98682 9.17004 2.98682 8.97487 3.18198L6.5 5.65685L4.02513 3.18198C3.82996 2.98682 3.51318 2.98682 3.31802 3.18198C3.12286 3.37714 3.12286 3.69393 3.31802 3.88909L5.79289 6.36396L3.31802 8.83883C3.12286 9.034 3.12286 9.35078 3.31802 9.54594C3.51318 9.7411 3.82996 9.7411 4.02513 9.54594L6.5 7.07107L8.97487 9.54594C9.17004 9.7411 9.48682 9.7411 9.68198 9.54594C9.87714 9.35078 9.87714 9.034 9.68198 8.83883Z');

typedef TabSelectedCallback = void Function(RiveTabItem item);

class _TabBarItem extends StatelessWidget {
  final RiveTabItem tab;
  final bool isSelected;
  final TabSelectedCallback select;

  const _TabBarItem({Key key, this.tab, this.isSelected, this.select})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => select?.call(tab),
      child: Container(
        padding: EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        child: Row(
          children: [
            Text(
              tab.name,
              style: TextStyle(
                fontFamily: 'Roboto-Regular',
                fontSize: 13,
                color: isSelected
                    ? Colors.white
                    : Color.fromRGBO(140, 140, 140, 1.0),
              ),
            ),
            if (tab.closeable) SizedBox(width: 10),
            if (tab.closeable)
              PathWidget(
                path: _closeIcon,
                nudge: Offset(0.5, 0),
                paint: Paint()
                  ..color = Color.fromRGBO(140, 140, 140, 1.0)
                  ..style = PaintingStyle.stroke
                  ..isAntiAlias = false,
              )
          ],
        ),
        decoration: isSelected
            ? TabDecoration(color: Color.fromRGBO(60, 60, 60, 1.0))
            : null,
      ),
    );
  }
}

class RiveTabBar extends StatelessWidget {
  final List<RiveTabItem> tabs;
  final RiveTabItem selected;
  final double offset;
  final TabSelectedCallback select;

  const RiveTabBar(
      {Key key, this.tabs, this.offset = 0, this.selected, this.select})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      SizedBox(width: offset),
      ...tabs
          .map(
            (tab) => _TabBarItem(
              tab: tab,
              isSelected: selected == tab,
              select: select,
            ),
          )
          .toList(growable: false),
    ]);
  }
}
