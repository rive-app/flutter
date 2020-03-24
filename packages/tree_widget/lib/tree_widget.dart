library tree_widget;

import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'flat_tree_item.dart';
import 'tree_controller.dart';
import 'tree_line.dart';
import 'tree_style.dart';

typedef ChildrenFunction = List<Object> Function(Object treeItem);

typedef IsFunction = bool Function(Object treeItem);
typedef SpacingFunction = int Function(Object treeItem);
typedef TreeViewExtraPartBuilder<T> = Widget Function(
    BuildContext context, FlatTreeItem<T> item, int spaceIndex);
typedef TreeViewPartBuilder<T> = Widget Function(
    BuildContext context, FlatTreeItem<T> item);
typedef TreeViewIndexBuilder<T> = Widget Function(
    BuildContext context, int index);

class TreeView<T> extends StatelessWidget {
  /// The controller used to provide data and extract hierarchical information
  /// from the data items. Also used to track expanded/collapsed items.
  final TreeController<T> controller;

  /// Builder used to create the expander widget.
  final TreeViewPartBuilder<T> expanderBuilder;

  /// Builder used to create the icon widget.
  final TreeViewPartBuilder<T> iconBuilder;

  /// Most items take up one unit of space. If the item takes up more than 1
  /// unit, this builder will be called for every extra unit. This allows adding
  /// extra elements to the tree row prior to the icon. Lines will be spaced
  /// accordingly. Note that extra spaces are also required to be [iconSize]
  /// dimensions.
  final TreeViewExtraPartBuilder<T> extraBuilder;

  /// Builder used to build the main content of the TreeView's item. This
  /// usually has text in it.
  final TreeViewPartBuilder<T> itemBuilder;

  /// Builder for the background of the item, return null if you don't want a
  /// background.
  final TreeViewPartBuilder<T> backgroundBuilder;

  /// Styling (colors, margins, padding) for the tree.
  final TreeStyle style;

  final ScrollController scrollController;

  final bool shrinkWrap;

  final TreeViewIndexBuilder separatorBuilder;

  final List<Widget> trailingWidgets;

  const TreeView(
      {@required this.controller,
      @required this.expanderBuilder,
      @required this.iconBuilder,
      @required this.itemBuilder,
      this.separatorBuilder,
      this.extraBuilder,
      this.backgroundBuilder,
      this.style = defaultTreeStyle,
      this.scrollController,
      this.shrinkWrap = false,
      this.trailingWidgets = const []});

  @override
  Widget build(BuildContext context) {
    assert(style != null);
    var iconWidth = style.iconSize.width;
    var iconHeight = style.iconSize.height;
    var lineColor = style.lineColor;
    var propertyDashPattern = style.propertyDashPattern;
    var itemHeight = style.itemHeight;
    var padIndent = style.padIndent;
    var iconMargin = style.iconMargin;
    var inactiveOpacity = style.inactiveOpacity;

    return ChangeNotifierProvider<TreeController<T>>.value(
      value: controller,
      child: Consumer<TreeController<T>>(
        builder: (context, controller, _) => Scrollbar(
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            controller: scrollController,
            // semanticChildCount: controller.flat.length,
            shrinkWrap: shrinkWrap,
            padding: style.padding,
            // itemExtent: style.itemHeight,
            itemBuilder: (context, index) {
              if (index >= controller.flat.length) {
                return trailingWidgets[index - controller.flat.length];
              }
              var item = controller.flat[index];
              if (item == null) {
                if (separatorBuilder != null) {
                  return Container(
                    height: itemHeight,
                    child: separatorBuilder(context, index),
                  );
                }
                return Container();
              }
              var lines = <Widget>[];
              var depth = item.depth;

              if (style.showFirstLine) {
                depth = Int8List.fromList(
                  depth.toList(growable: true)..insert(0, 0),
                );
              } else if (depth.isNotEmpty) {
                depth[0] = -1;
              }
              int depthCount = depth.length;
              bool hasChildren = item.hasChildren;
              int numberOfLines = hasChildren ? depthCount - 1 : depthCount;
              bool shortLastLine = !hasChildren && item.isLastChild;
              numberOfLines--;
              double toLineCenter = iconWidth / 2;
              double offset = toLineCenter; // 20 + toLineCenter;
              double indent = iconWidth + style.padIndent;
              bool showLines = !style.hideLines;
              int dragDepth = item.dragDepth ?? 255;
              for (var i = 0; i < numberOfLines; i++) {
                double opacity = 1.0;
                var d = depth[i];
                offset += indent * (d.abs() - 1);
                if (d > 0) {
                  // var style = {left:px(offset)};
                  if (i >= dragDepth || item.isDisabled) {
                    //style.opacity = DragOpacity;
                    opacity = inactiveOpacity;
                  }

                  lines.add(
                    Positioned(
                      top: -0.5,
                      bottom: -0.5,
                      left: offset,
                      child: Container(
                        width: 1,
                        child: CustomPaint(
                          painter: TreeLine(
                            color: lineColor
                                .withOpacity(lineColor.opacity * opacity),
                            strokeCap: StrokeCap.butt,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                offset += indent;
              }

              var opacity = 1.0;

              var lastLineSpace =
                  numberOfLines < depth.length && numberOfLines > 0
                      ? depth[numberOfLines]
                      : 0;
              if (lastLineSpace > 0 && !(index == 0 && item.isLastChild)) {
                bool isPropertyLine = !item.hasChildren && item.isProperty;
                // let lastLineStyle = !item.hasChildren && item.isProperty ? styles.PropertyLine : styles.Line;
                if (lastLineSpace > 1) {
                  offset += (lastLineSpace - 1) * indent;
                }
                double top = 0;
                double bottom = shortLastLine ? itemHeight / 2 : 0;
                // let style = {bottom:shortLastLine ? "50%" : null, left:px(offset)};

                if (index == 0) {
                  // Correction for this case: https://cl.ly/3d300n1C2E0E where the line extends up instead we want it to look like this on the first item: https://cl.ly/2U1U3Z1h0D2D
                  top = itemHeight / 2;
                  bottom = 0;
                  // style.bottom = "0";
                }
                if (numberOfLines >= dragDepth || item.isDisabled) {
                  opacity = inactiveOpacity;
                  // style.opacity = DragOpacity;
                }
                // verticalLines.push(<div className={lastLineStyle} key={numberOfLines} style={style}></div>);
                lines.add(
                  Positioned(
                    left: offset,
                    top: top - 0.5,
                    bottom: bottom - 0.5,
                    child: Container(
                      width: 1,
                      child: CustomPaint(
                        painter: TreeLine(
                          dashPattern: !item.hasChildren && item.isProperty
                              ? propertyDashPattern
                              : null,
                          color: lineColor
                              .withOpacity(lineColor.opacity * opacity),
                          strokeCap: StrokeCap.butt,
                        ),
                      ),
                    ),
                  ),
                );
              }

              var spaces = -1;
              for (final s in depth) {
                spaces += s.abs();
              }
              double spaceLeft = spaces * indent;

              var dashing = item.isProperty ? propertyDashPattern : null;

              bool showOurLine = depth[depth.length - 1] != -1;

              var nextDragDepth = 255;
              var prevDragDepth = 255;
              bool isNextProperty = item.next?.isProperty ?? false;
              var nextDepth = item.next?.depth;
              if (dragDepth != null) {
                if (item.prev != null) {
                  prevDragDepth = item.prev.dragDepth;
                }
                if (item.next != null) {
                  nextDragDepth = item.next.dragDepth;
                }
              }

              bool dragging = numberOfLines + 2 >= dragDepth;

              double dragOpacity =
                  dragging || item.isDisabled ? inactiveOpacity : 1.0;
              double aboveDragOpacity =
                  dragging && prevDragDepth != null ? inactiveOpacity : 1.0;
              double belowDragOpacity =
                  numberOfLines + 1 >= dragDepth && nextDragDepth != null
                      ? inactiveOpacity
                      : 1.0;

              if (hasChildren) {
                if (showLines && showOurLine && index != 0) {
                  // Example: Red connector above expander: https://cl.ly/0Z452u3b3S1z
                  // <div className={styles.ConnectorLine} style={{height:px((rowHeight-iconSize)/2), top:px(-(rowHeight-iconSize)/2-1), bottom:"initial", opacity:aboveDragOpacity}}></div>}
                  lines.insert(
                    0,
                    Positioned(
                      left: spaceLeft + iconWidth / 2,
                      top: 0.5,
                      child: Container(
                        width: 1,
                        height: (itemHeight - iconHeight) / 2,
                        child: CustomPaint(
                          painter: TreeLine(
                            color: lineColor.withOpacity(
                                lineColor.opacity * aboveDragOpacity),
                            strokeCap: StrokeCap.butt,
                          ),
                        ),
                      ),
                    ),
                  );
                }
                if (showLines && showOurLine && !item.isLastChild) {
                  // Example: Red connector under expander: https://cl.ly/473J3m462g0e
                  lines.insert(
                    0,
                    Positioned(
                      left: spaceLeft + iconWidth / 2,
                      top: itemHeight / 2 + iconHeight / 2 + 0.5,
                      child: Container(
                        width: 1,
                        // extra 0.5 here to avoid precision errors leaving a
                        // gap
                        height: (itemHeight - iconHeight) / 2 + 1.5,
                        child: CustomPaint(
                          painter: TreeLine(
                            color: lineColor.withOpacity(
                                lineColor.opacity * belowDragOpacity),
                            strokeCap: StrokeCap.butt,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              } else if (!(depth.length == 1 && depth[0] == -1)) {
                //(this.props.hideFirstHorizontalLine && depth.length === 1 && depth[0] === -1) ? null : <div className={horizontalLineStyle} style={{background:showOurLine && showLines ? null : "initial", opacity:dragOpacity}}></div>
                lines.insert(
                  0,
                  Positioned(
                    left: spaceLeft + iconWidth / 2,
                    top: itemHeight / 2,
                    child: Container(
                      width: iconWidth / 2 + padIndent - iconMargin,
                      height: 1,
                      child: CustomPaint(
                        painter: TreeLine(
                          dashPattern: dashing,
                          color: lineColor
                              .withOpacity(lineColor.opacity * dragOpacity),
                          strokeCap: StrokeCap.butt,
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (item.isExpanded && showLines) {
                // Example: https://cl.ly/1D1j2p0d1k1N connector red line below torso and head
                // <div className={isNextProperty && nextDepth.length - depth.length === 1 ? styles.IconPropertyConnectorLine : styles.IconConnectorLine} style={{marginLeft:px(Math.floor(space*Indent+ToLineCenter)), top:px(rowHeight/2+iconHeight/2), opacity:dragOpacity}}></div> : null
                // marginLeft:px(Math.floor(space*Indent+ToLineCenter)), top:px(rowHeight/2+iconHeight/2)
                lines.insert(
                  0,
                  Positioned(
                    left: spaceLeft + (item.spacing * indent) + iconWidth / 2,
                    top: itemHeight / 2 + iconHeight / 2 + 0.5,
                    child: Container(
                      width: 1,
                      height: (itemHeight - iconHeight) / 2 + 1.5,
                      child: CustomPaint(
                        painter: TreeLine(
                          color: lineColor
                              .withOpacity(lineColor.opacity * dragOpacity),
                          strokeCap: StrokeCap.butt,
                        ),
                      ),
                    ),
                  ),
                );
              }

              if (backgroundBuilder != null) {
                lines.add(
                  Positioned(
                    left: indent + spaceLeft - iconMargin / 2,
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: _InputHelper<T>(
                      style: style,
                      isDragging: dragging,
                      item: item,
                      child: backgroundBuilder(context, item),
                    ),
                  ),
                );
                // Draw background before lines?
                //lines.insert(0, value);
              }

              return KeepAlive(
                /// We need a KeepAlive here to make sure the input helper
                /// stays around when it's being dragged.
                key: item.key,
                keepAlive: controller.dragOperation?.startItem == item,
                child: Container(
                  height: itemHeight,
                  child: Stack(
                    overflow: Overflow.visible,
                    children: <Widget>[
                      Positioned.fill(
                        top: 0,
                        child: Stack(
                          children: lines,
                          overflow: Overflow.visible,
                        ),
                      ),
                      Positioned(
                        left: spaceLeft,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Opacity(
                          opacity: dragOpacity,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ...hasChildren
                                  ? [
                                      Container(
                                        padding:
                                            EdgeInsets.only(right: padIndent),
                                        width: indent,
                                        height: iconHeight,
                                        child: GestureDetector(
                                          onTap: () {
                                            if (item.isExpanded) {
                                              controller.collapse(item.data);
                                            } else {
                                              controller.expand(item.data);
                                            }
                                          },
                                          child: expanderBuilder(context, item),
                                        ),
                                      ),
                                    ]
                                  : [SizedBox(width: indent)],
                              for (int i = 0; i < item.spacing - 1; i++)
                                Container(
                                  margin: EdgeInsets.only(right: padIndent),
                                  width: iconWidth,
                                  height: iconHeight,
                                  child: extraBuilder?.call(context, item, i),
                                ),
                              Container(
                                margin: EdgeInsets.only(right: padIndent),
                                width: iconWidth,
                                height: iconHeight,
                                child: IgnorePointer(
                                  child: iconBuilder(context, item),
                                ),
                              ),
                              itemBuilder(context, item),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            itemCount: controller?.flat?.length + trailingWidgets.length ??
                trailingWidgets.length,
            // findChildIndexCallback: (Key key) {
            //   return controller.indexLookup[key];
            // },
            addRepaintBoundaries: false,
            addAutomaticKeepAlives: false,
            addSemanticIndexes: false,
          ),
        ),
      ),
    );
  }
}

class _InputHelper<T> extends StatelessWidget {
  final Widget child;
  final bool isDragging;
  final FlatTreeItem<T> item;
  final TreeStyle style;

  const _InputHelper(
      {Key key, this.child, this.isDragging, this.item, this.style})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    var controller = Provider.of<TreeController<T>>(context);
    return IgnorePointer(
      ignoring: isDragging,
      child: MouseRegion(
        opaque: false,
        // onHover:  controller.isDragging
        //     ? null
        //     : (event) {
        //         return controller.onMouseEnter(null, item);
        //       },
        onEnter: controller.isDragging
            ? null
            : (event) {
                return controller.onMouseEnter(event, item);
              },
        onExit: (event) => controller.onMouseExit(event, item),
        child: Listener(
          onPointerDown: (event) {},
          onPointerMove: (event) {
            // print("MOVE ${event.localPosition}");
          },
          child: GestureDetector(
            onTap: () => controller.onTap(item),
            onVerticalDragStart: (details) {
              var toDrag = controller.onDragStart(details, item);
              if (toDrag != null && toDrag.isNotEmpty) {
                controller.startDrag(details, context, item, toDrag);
              }
            },
            onVerticalDragEnd: (details) {
              controller.stopDrag();
            },
            onVerticalDragUpdate: (details) {
              controller.updateDrag(context, details, item, style);
              // print(
              //     "EVENT2 ${item.data} ${window.devicePixelRatio} ${details.localPosition.dy} ${details.localPosition.dy / window.devicePixelRatio}");
              // print("UPDATE DRAG ${details.globalPosition}");
            },
            child: child,
          ),
        ),
      ),
    );
  }
}
