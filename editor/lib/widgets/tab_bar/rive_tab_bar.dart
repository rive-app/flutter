import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

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

typedef TabSelectedCallback = void Function(RiveTabItem item);

class _TabBarItem extends StatelessWidget {
  final RiveTabItem tab;
  final bool isSelected;
  final TabSelectedCallback select, close;

  const _TabBarItem({
    Key key,
    this.tab,
    this.isSelected,
    this.select,
    this.close,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => select?.call(tab),
      child: Container(
        padding:
            const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
        child: Row(
          children: [
            Text(
              tab.name,
              style: TextStyle(
                fontSize: 13,
                color: isSelected
                    ? RiveTheme.of(context).colors.tabTextSelected
                    : RiveTheme.of(context).colors.tabText,
              ),
            ),
            if (tab.closeable) const SizedBox(width: 10),
            if (tab.closeable)
              GestureDetector(
                onTap: close == null ? null : () => close(tab),
                child: RiveIcons.close(Color.fromRGBO(140, 140, 140, 1.0), 13),
              )
          ],
        ),
        decoration: isSelected
            ? TabDecoration(
                color: RiveTheme.of(context).colors.tabBackgroundSelected)
            : null,
      ),
    );
  }
}

class _UserTabBarItem extends StatelessWidget {
  final RiveTabItem tab;
  final bool isSelected;
  final TabSelectedCallback select, close;

  const _UserTabBarItem({
    Key key,
    this.tab,
    this.isSelected,
    this.select,
    this.close,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => select?.call(tab),
      child: Container(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 10,
          bottom: 10,
        ),
        child: Row(
          children: [
            TintedIcon(
                color: isSelected
                    ? RiveTheme.of(context).colors.tabRiveTextSelected
                    : RiveTheme.of(context).colors.tabRiveText,
                icon: 'rive'),
            if (tab.closeable) const SizedBox(width: 10),
            if (tab.closeable)
              GestureDetector(
                onTap: close == null ? null : () => close(tab),
                child: RiveIcons.close(
                    const Color.fromRGBO(140, 140, 140, 1.0), 13),
              )
          ],
        ),
        decoration: isSelected
            ? TabDecoration(
                color: RiveTheme.of(context).colors.tabRiveBackgroundSelected)
            : null,
      ),
    );
  }
}

class RiveTabBar extends StatelessWidget {
  final List<RiveTabItem> tabs;
  final RiveTabItem selected;
  final double offset;
  final TabSelectedCallback select, close;

  const RiveTabBar(
      {Key key,
      this.tabs,
      this.offset = 0,
      this.selected,
      this.select,
      this.close})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: offset),
        for (int i = 0; i < tabs.length; i++)
          i == 0
              ? _UserTabBarItem(
                  tab: tabs[i],
                  isSelected: selected == tabs[i],
                  select: select,
                  close: close,
                )
              : _TabBarItem(
                  tab: tabs[i],
                  isSelected: selected == tabs[i],
                  select: select,
                  close: close,
                ),
      ],
    );
  }
}
