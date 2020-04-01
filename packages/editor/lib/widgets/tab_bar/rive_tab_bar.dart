import 'package:cursor/propagating_listener.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/widgets/common/hit_deny.dart';
import 'package:rive_editor/widgets/common/rive_scroll_view.dart';

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

const double _dynamicTabWidth = 240;

class TabItem extends StatefulWidget {
  final VoidCallback select;
  final VoidCallback close;
  final bool isSelected;
  final bool canClose;
  final bool invertLeft;
  final bool invertRight;
  final bool separator;
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
    this.separator = true,
  }) : super(key: key);

  @override
  _TabItemState createState() => _TabItemState();
}

class _TabItemState extends State<TabItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return HitAllow(
      child: PropagatingListener(
        behavior: HitTestBehavior.deferToChild,
        onPointerDown: (_) => widget.select?.call(),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          // Can't use gesture detector as we're IgnorePointering the scrolling
          // list that contains this. I thought IgnorePointer would only ignore
          // hit testing on that one item, but it seems to propgate down to
          // children like AbsorbPointer does.
          child: Container(
            width: widget.canClose ? _dynamicTabWidth : null,
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
                  PropagatingListener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: widget.close == null
                        ? null
                        : (event) {
                            event.stopPropagation();
                            widget.close?.call();
                          },
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
                    fill: true,
                    separator: widget.separator,
                  )
                : _hover
                    ? TabDecoration(
                        color:
                            RiveTheme.of(context).colors.tabBackgroundHovered,
                        invertLeft: widget.invertLeft,
                        invertRight: widget.invertRight,
                        fill: true,
                        separator: widget.separator,
                      )
                    : widget.separator
                        ? TabDecoration(
                            color:
                                RiveTheme.of(context).colors.tabRiveSeparator,
                            fill: false,
                            separator: true,
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
          separator: i != dockedTabs.length - 1,
        ),
      );
    }
    return CustomMultiChildLayout(
      delegate: _TabLayoutDelegate(),
      children: [
        LayoutId(
          id: _Tabs.scrolling,
          child: ScrollingTabList(
            tabs: dynamicTabs,
            selectedIndex: selectedIndex,
            firstTabIndex: dockedTabs.length,
            select: select,
            close: close,
          ),
        ),
        LayoutId(
          id: _Tabs.docked,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: dockedTabWidgets,
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

const double _fadeWidth = 20;

class _ScrollingTabListState extends State<ScrollingTabList> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(ScrollingTabList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex &&
        widget.selectedIndex >= 0) {
      var index = widget.selectedIndex - widget.firstTabIndex;
      if (index < 0) {
        // don't move if a docked tab was selected.
        return;
      }
      var range = _controller.position.viewportDimension;

      var origin = -_controller.offset + _dynamicTabWidth * index;
      // Are we off to the left in the negative range.
      if (origin < 0) {
        _controller.position.moveTo(
          _controller.offset + origin,
          duration: const Duration(milliseconds: 200),
        );
      }
      // Are we off to the right?
      else if (origin + _dynamicTabWidth > range) {
        _controller.position.moveTo(
          _controller.offset + (origin + _dynamicTabWidth - range),
          duration: const Duration(milliseconds: 200),
          // Let it go off to the right if the scroll view hasn't got the
          // content yet (race condition while building)
          clamp: false,
        );
      }
    }
  }

  double _fadeOpacity = 0;

  bool _showFade = false;
  void _scrolled() {
    var show = _controller.offset > 0;

    double opacity = (_controller.offset / _fadeWidth).clamp(0, 1).toDouble();
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

    return Listener(
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
        child: _TabFader(
          opacity: _fadeOpacity,
          color: theme.colors.tabRiveBackground,
          separator: theme.colors.tabRiveSeparator,
          child: RiveScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            drawOrder: DrawOrder.lifo,
            overflow: Overflow.visible,
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => TabItem(
                    isSelected:
                        widget.selectedIndex == widget.firstTabIndex + index,
                    canClose: true,
                    close: () => widget.close(widget.tabs[index]),
                    select: () => widget.select(widget.tabs[index]),
                    builder: (context, hovered, selected) =>
                        ValueListenableBuilder<String>(
                      valueListenable: widget.tabs[index].file.name,
                      builder: (context, name, child) => Expanded(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
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
                    ),
                    invertLeft: widget.selectedIndex ==
                        index + widget.firstTabIndex - 1,
                    invertRight: widget.selectedIndex ==
                        index + widget.firstTabIndex + 1,
                    // don't draw the last separator
                    separator: index != widget.tabs.length - 1,
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
    );
  }
}

/// Draws a gradient edge (from backround color to transparent) on the left hand
/// side of the tab list to make the file tabs look like they're fading out as
/// they approach the static ones.
class _TabFader extends SingleChildRenderObjectWidget {
  final Color color;
  final Color separator;
  final double opacity;

  const _TabFader({
    Key key,
    Widget child,
    this.color,
    this.opacity,
    this.separator,
  }) : super(key: key, child: child);

  @override
  _RenderTabFader createRenderObject(BuildContext context) {
    return _RenderTabFader(
      color: color,
      opacity: opacity,
      separator: separator,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderTabFader renderObject) {
    renderObject
      ..color = color
      ..opacity = opacity
      ..separator = separator;
  }
}

class _RenderTabFader extends RenderProxyBox {
  double _opacity;
  double get opacity => _opacity;
  set opacity(double value) {
    if (_opacity == value) {
      return;
    }
    _opacity = value;
    markNeedsPaint();
  }

  Color _color;
  Color get color => _color;
  set color(Color value) {
    if (_color == value) {
      return;
    }
    _color = value;
    markNeedsPaint();
  }

  Color _separator;
  Color get separator => _separator;
  set separator(Color value) {
    if (_separator == value) {
      return;
    }
    _separator = value;
    markNeedsPaint();
  }

  _RenderTabFader({
    RenderBox child,
    double opacity,
    Color color,
    Color separator,
  })  : _opacity = opacity,
        _color = color,
        _separator = separator,
        super(child);

  void _paintChild(PaintingContext context, Offset offset) {
    context.paintChild(child, offset);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final fadeRect = Rect.fromLTWH(
        offset.dx, offset.dy, _fadeWidth, size.height);
    final clipRect =
        Rect.fromLTWH(0, 0, size.width, size.height);


    final rect = offset & size;//Rect.lerp(offset & size, fadeRect, opacity);
    
    context.canvas.drawLine(
      rect.topLeft.translate(0, TabDecoration.cornerRadius + 1),
      rect.bottomLeft.translate(0, -TabDecoration.cornerRadius - 1),
      Paint()..color = separator,
    );

    if(opacity > 0.1) {
    layer = context.pushClipRect(
      needsCompositing,
      offset,
      clipRect,
      _paintChild,
      oldLayer: layer is ClipRectLayer ? layer as ClipRectLayer : null,
      clipBehavior: Clip.hardEdge
    );
    }
    else {
      _paintChild(context, offset);
    }

    if (opacity > 0) {
      var canvas = context.canvas;
      canvas.drawRect(
        fadeRect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              color.withOpacity(opacity),
              color.withOpacity(0),
            ],
          ).createShader(fadeRect),
      );
    }
  }
}

enum _Tabs { docked, scrolling }

/// This basically works like a row, draw docked tabs followed by scrolling ones
/// horizontally. The only reason we have a custom layout delegate is so we can
/// provide the items in whatever draw order we want them (row doesn't allow
/// switching draw and alignment order).
class _TabLayoutDelegate extends MultiChildLayoutDelegate {
  @override
  bool shouldRelayout(_TabLayoutDelegate oldDelegate) => false;

  @override
  void performLayout(Size size) {
    // Layout the docked tabs on the left of this box.
    var dockedSize = layoutChild(
      _Tabs.docked,
      BoxConstraints(maxHeight: size.height, maxWidth: size.width),
    );

    // Layout the scrolling tabs immediately to the right of the docked ones.
    layoutChild(_Tabs.scrolling,
        BoxConstraints.tight(Size(size.width - dockedSize.width, size.height)));
    positionChild(_Tabs.docked, Offset.zero);
    positionChild(_Tabs.scrolling, Offset(dockedSize.width, 0));
  }
}
