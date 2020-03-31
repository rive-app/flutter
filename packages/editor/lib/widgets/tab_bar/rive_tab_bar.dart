import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/common/hit_deny.dart';

import 'package:rive_editor/widgets/icons.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

import 'tab_decoration.dart';

/// Describes a Rive tab item.
class RiveTabItem {
  const RiveTabItem({
    this.icon,
    this.closeable = true,
    this.file,
  });
  final OpenFileContext file;
  final String icon;
  final bool closeable;
}

typedef TabSelectedCallback = void Function(RiveTabItem item);

typedef TabItemBuilder = Widget Function(
    BuildContext context, bool isHovered, bool isSelected);

class TabItem extends StatefulWidget {
  final VoidCallback select;
  final VoidCallback close;
  final bool isSelected;
  final bool canClose;
  final bool invertLeft;
  final bool invertRight;
  final TabItemBuilder builder;

  const TabItem({
    Key key,
    this.select,
    this.close,
    this.isSelected = false,
    this.canClose = false,
    this.invertLeft = false,
    this.invertRight = false,
    this.builder,
  }) : super(key: key);

  @override
  _TabItemState createState() => _TabItemState();
}

class _TabItemState extends State<TabItem> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return HitAllow(
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onTapDown: (_) => widget.select?.call(),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          // Can't use gesture detector as we're IgnorePointering the scrolling
          // list that contains this. I thought IgnorePointer would only ignore
          // hit testing on that one item, but it seems to propgate down to
          // children like AbsorbPointer does.
          child: Container(
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 10,
              bottom: 10,
            ),
            child: Row(
              children: [
                widget.builder(context, _hover, widget.isSelected),
                if (widget.canClose) const SizedBox(width: 10),
                if (widget.canClose)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: widget.close == null
                        ? null
                        : (_) => widget.close?.call(),
                    child: const CloseIcon(),
                  )
              ],
            ),
            decoration: widget.isSelected
                ? TabDecoration(
                    color: widget.canClose
                        ? RiveTheme.of(context).colors.tabBackgroundSelected
                        : RiveTheme.of(context)
                            .colors
                            .tabRiveBackgroundSelected,
                    invertLeft: widget.invertLeft,
                    invertRight: widget.invertRight,
                  )
                : _hover
                    ? TabDecoration(
                        color:
                            RiveTheme.of(context).colors.tabBackgroundHovered,
                        invertLeft: widget.invertLeft,
                        invertRight: widget.invertRight,
                      )
                    : null,
          ),
        ),
      ),
    );
  }
}

class DockingTabBar extends StatelessWidget {
  final List<RiveTabItem> dockedTabs;
  final List<RiveTabItem> dynamicTabs;
  final RiveTabItem selectedTab;
  final TabSelectedCallback select, close;

  const DockingTabBar({
    @required this.dockedTabs,
    @required this.dynamicTabs,
    this.selectedTab,
    this.select,
    this.close,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int selectedIndex = dockedTabs.indexOf(selectedTab);
    if (selectedIndex == -1) {
      selectedIndex = dockedTabs.length + dynamicTabs.indexOf(selectedTab);
    }

    var dockedTabWidgets = <Widget>[];
    for (int i = 0; i < dockedTabs.length; i++) {
      var tab = dockedTabs[i];
      dockedTabWidgets.add(
        TabItem(
          isSelected: tab == selectedTab,
          canClose: false,
          select: () => select(tab),
          builder: (context, hovered, selected) => TintedIcon(
            color: selected
                ? RiveTheme.of(context).colors.tabRiveTextSelected
                : hovered
                    ? RiveTheme.of(context).colors.tabTextSelected
                    : RiveTheme.of(context).colors.tabRiveText,
            icon: tab.icon,
          ),
          invertLeft: selectedIndex == i - 1,
          invertRight: selectedIndex == i + 1,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        ...dockedTabWidgets,
        Expanded(
          child: ScrollingTabList(
            tabs: dynamicTabs,
            selectedIndex: selectedIndex,
            firstTabIndex: dockedTabs.length,
            select: select,
            close: close,
          ),
        ),
      ],
    );
  }
}

/// TODO: make this not swallow the tapDown event as it's prevenging dragging th
/// window.
///
/// Virtualized list of scrolling tabs used to represent the currently open Rive
/// files.
class ScrollingTabList extends StatefulWidget {
  final List<RiveTabItem> tabs;
  final TabSelectedCallback select, close;
  final int selectedIndex;
  final int firstTabIndex;

  const ScrollingTabList({
    Key key,
    this.tabs,
    this.select,
    this.close,
    this.selectedIndex,
    this.firstTabIndex,
  }) : super(key: key);

  @override
  _ScrollingTabListState createState() => _ScrollingTabListState();
}

class _ScrollingTabListState extends State<ScrollingTabList> {
  final ScrollController _controller = ScrollController();

  static const double fadeWidth = 10;
  double _fadeOpacity;

  bool _showFade = false;
  void _scrolled() {
    var show = _controller.offset > 0;

    double opacity = (_controller.offset / fadeWidth).clamp(0, 1).toDouble();
    if (show != _showFade || opacity != _fadeOpacity) {
      setState(() {
        _showFade = show;
        _fadeOpacity = opacity;
      });
    }
  }

  @override
  void initState() {
    _controller.addListener(_scrolled);
    super.initState();
  }

  @override
  void dispose() {
    _controller.removeListener(_scrolled);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var theme = RiveTheme.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerSignal: (details) {
              if (details is PointerScrollEvent) {
                // TODO: trackpad should use dx instead of dy, but how do we
                // disambiguate when details.kind is always mouse?
                _controller.position
                    .moveTo(_controller.offset + details.scrollDelta.dy);
              }
            },
            child: HitDeny(
              child: CustomScrollView(
                controller: _controller,
                scrollDirection: Axis.horizontal,
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => TabItem(
                        isSelected: widget.selectedIndex ==
                            widget.firstTabIndex + index,
                        canClose: true,
                        close: () => widget.close(widget.tabs[index]),
                        select: () => widget.select(widget.tabs[index]),
                        builder: (context, hovered, selected) =>
                            ValueListenableBuilder<String>(
                          valueListenable: widget.tabs[index].file.name,
                          builder: (context, name, child) => Text(
                            name,
                            style: TextStyle(
                              fontSize: 13,
                              color: selected
                                  ? theme.colors.tabTextSelected
                                  : hovered
                                      ? theme.colors.tabTextSelected
                                      : theme.colors.tabText,
                            ),
                          ),
                        ),
                        invertLeft: widget.selectedIndex ==
                            index + widget.firstTabIndex - 1,
                        invertRight: widget.selectedIndex ==
                            index + widget.firstTabIndex + 1,
                      ),
                      childCount: widget.tabs.length,
                      addAutomaticKeepAlives: false,
                      addRepaintBoundaries: false,
                      addSemanticIndexes: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          width: fadeWidth,
          top: 0,
          bottom: 0,
          child: _showFade
              ? CustomPaint(
                  painter: LeftFade(
                    from: theme.colors.tabRiveBackground
                        .withOpacity(_fadeOpacity),
                    to: theme.colors.tabRiveBackground.withOpacity(0),
                  ),
                )
              : const SizedBox(),
        ),
      ],
    );
  }
}

/// Draws a gradient edge (from backround color to transparent) on the left hand
/// side of the tab list to make the file tabs look like they're fading out as
/// they approach the static ones.
class LeftFade extends CustomPainter {
  final Color from;
  final Color to;
  const LeftFade({this.from, this.to});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            from,
            to,
          ],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(LeftFade oldDelegate) =>
      oldDelegate.from != from || oldDelegate.to != to;
}
