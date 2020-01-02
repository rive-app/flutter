library tree_widget;

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tree_widget/tree_line.dart';

typedef ChildrenFunction = List<Object> Function(Object treeItem);

typedef IsFunction = bool Function(Object treeItem);
typedef SpacingFunction = int Function(Object treeItem);
typedef TreeViewPartBuilder<T> = Widget Function(
    BuildContext context, FlatTreeItem<T> item);
typedef TreeViewExtraPartBuilder<T> = Widget Function(
    BuildContext context, FlatTreeItem<T> item, int spaceIndex);
typedef TreeViewBackgroundBuilder<T> = Widget Function(
    BuildContext context, FlatTreeItem<T> item, double offset);

/// Context used internally to flatten the tree.
class FlattenedTreeDataContext {
  final Set<Object> expanded;
  int lastDepth = 0;
  FlatTreeItem prev;

  FlattenedTreeDataContext(this.expanded);
}

/// Tree data that has the hierarchy flattened, making it possible to render the
/// tree from virtualized (one dimensional) array.
class FlatTreeItem<T> {
  /// Key used to track the widget created for this item.
  final Key key;

  /// Reference back to the hierarchical node represented by this flat
  /// structure.
  final T data;

  /// Previous flattened sibling.
  final FlatTreeItem prev;

  /// Next flattened sibling.
  FlatTreeItem next;

  /// Parent [FlatTreeItem] from the hierarchy.
  final FlatTreeItem parent;

  /// Depths stored as a Uint8List. Each entry represents a horizontal space to
  /// move right by. If the entry is positive, a solid vertical line should also
  /// be drawn. This is used to connect up the lines in the hierarchy.
  final Int8List depth;

  /// Whether this is the last of the siblings under [parent].
  final bool isLastChild;

  /// Whether this item has more children which can be expanded.
  final bool hasChildren;

  /// Whether this item is expanded.
  final bool isExpanded;

  /// How many unit (line) spaces this column occupies.
  final int spacing;

  /// Whether this is item can be interacted with or not.
  final bool isDisabled;

  /// Whether this item is a property.
  final bool isProperty;

  /// The depth of where this item is dragged from. null when not dragged.
  int dragDepth;

  FlatTreeItem(this.data,
      {this.parent,
      this.next,
      this.prev,
      this.depth,
      this.isLastChild,
      this.hasChildren,
      this.isExpanded,
      this.spacing,
      this.isDisabled,
      this.isProperty = false})
      : key = ValueKey(data);
}

/// A helper to inherit from when creating a TreeView with hierarchical data.
/// This helper lets the implementation specify how items relate to each other
/// hierarchically without needing each item to implement any specific
/// interfaces.
abstract class TreeController<T> extends ChangeNotifier {
  final Set<T> _expanded = {};
  List<FlatTreeItem<T>> _flat;
  Map<Key, int> _indexLookup;
  final List<T> _data;

  TreeController(this._data);

  /// The flattened data structure representing the hierarchical tree data that
  /// is currently expanded. This will be used by the TreeView to build a
  /// ListView with individual list items that connect via lines.
  List<FlatTreeItem<T>> get flat => _flat;

  /// Use this to opt out of flattening properties separately from other
  /// children. This is helpful when you have children that are of a different
  /// classification from others and want them to show up in a separate child
  /// sub-structure. If you know your tree won't need these, return false here
  /// to optimize away the extra computation needed to build these.
  bool get hasProperties => false;

  /// Return the children of T or null if none are available/treeItem doesn't
  /// have children.
  List<T> childrenOf(T treeItem);

  /// Hide the children of [item].
  void collapse(T item) {
    final expanded = _expanded;
    if (expanded.contains(item)) {
      expanded.remove(item);

      flatten();
    }
  }

  /// Show the children of [item].
  void expand(T item) {
    final expanded = _expanded;
    if (!expanded.contains(item)) {
      var children = childrenOf(item);
      if (children?.isNotEmpty ?? false) {
        expanded.add(item);
        flatten();
      }
    }
  }

  /// Flatten the structure from a hierarchical tree with parent child
  /// relationships to a linear array with indentation properties. This also
  /// generates metadata for widgets to draw lines connecting the tree and it
  /// generates a key to index lookup which will be used in Flutter's ListView
  /// widget to remap rows when items get expanded and their indices inherently
  /// change.
  void flatten() {
    var flat = <FlatTreeItem<T>>[];
    var context = FlattenedTreeDataContext(_expanded);
    var lookup = <Key, int>{};
    _flatten(context, _data, flat, lookup, [], null);
    _flat = flat;
    _indexLookup = lookup;
    notifyListeners();
  }

  /// Whether the [treeItem] can be interacted with.
  bool isDisabled(T treeItem);

  /// Return true if [treeItem] is a property and should be grouped separate
  /// from other children.
  bool isProperty(T treeItem);

  /// The units of horizontal spacing occupied by [treeItem]. Most items consume
  /// 1 unit of horizontal spacing. 1 unit of horizontal spacing equates to the
  /// icon size + some padding. In some cases tree items need extra units when
  /// they display some extra content before the icon.
  ///
  /// For example, in Rive the Solo items have an extra toggle that should be
  /// drawn before the icon.
  ///
  /// ![](https://rive-app.github.io/assets-for-api-docs/assets/tree-widget-flutter/extra_spacing.png)
  int spacingOf(T treeItem);

  void startDrag(List<FlatTreeItem<T>> items) {
    for (final item in items) {
      var dragDepth = item.depth.length;
      item.dragDepth = dragDepth;
      for (var next = item.next; next != null; next = next.next) {
        var p = next.parent;
        while (p != null) {
          if (p == item) {
            next.dragDepth = dragDepth;
            break;
          }
          p = p.parent;
        }
        if (p == null) {
          // item wasn't in our tree, we can early out from doing the rest.
          break;
        }
      }
    }
    notifyListeners();
  }

  void stopDrag() {
    for (final item in _flat) {
      item.dragDepth = null;
    }
    notifyListeners();
  }

  void _flatten(
      FlattenedTreeDataContext context,
      List<T> data,
      List<FlatTreeItem<T>> flat,
      Map<Key, int> lookup,
      List<int> depth,
      FlatTreeItem<T> parent) {
    // int depthIndex = depth.length;
    // depth.add(spacing);

    List<T> childItems;
    if (hasProperties) {
      childItems = [];
      List<T> propertyItems = [];
      for (final item in data) {
        if (isProperty(item)) {
          propertyItems.add(item);
          continue;
        }
        childItems.add(item);
      }
      int length = propertyItems.length;
      int childLength = childItems.length;
      for (int i = 0; i < length; i++) {
        var item = propertyItems[i];
        var spacing = spacingOf(item);
        var itemDepth = childLength == 0 ? depth : depth + [spacing, 1];

        var meta = FlatTreeItem(
          item,
          parent: parent,
          isProperty: true,
          prev: context.prev,
          next: null,
          depth: Int8List.fromList(itemDepth),
          isLastChild: i == length - 1,
          hasChildren: false,
          isExpanded: false,
          spacing: spacing,
          isDisabled: isDisabled(item),
        );
        if (context.prev != null) {
          context.prev.next = meta;
        }
        context.prev = meta;
        lookup[meta.key] = flat.length;
        flat.add(meta);
      }
    } else {
      childItems = data;
    }

    var childLength = childItems.length;
    for (int i = 0; i < childLength; i++) {
      var isLast = i == childLength - 1;
      var item = childItems[i];
      var spacing = spacingOf(item);
      var isExpanded = context.expanded.contains(item);
      var children = childrenOf(item);
      bool hasChildren = children?.isNotEmpty ?? false;
      var itemDepth = depth + [1];
      var meta = FlatTreeItem(
        item,
        parent: parent,
        prev: context.prev,
        next: null,
        depth: Int8List.fromList(itemDepth),
        isLastChild: isLast,
        hasChildren: hasChildren,
        isExpanded: hasChildren && isExpanded,
        spacing: spacing,
        isDisabled: isDisabled(item),
        isProperty: false,
      );
      if (context.prev != null) {
        context.prev.next = meta;
      }
      context.prev = meta;
      lookup[meta.key] = flat.length;
      flat.add(meta);
      if (isExpanded && hasChildren) {
        // update item depth for children
        int d = itemDepth.length - 1;
        if (spacing > 1) {
          itemDepth.add(-(spacing - 1));
        }

        itemDepth[d] = spacing < 0 || isLast ? -1 : 1;

        _flatten(
            context, children, flat, lookup, List<int>.from(itemDepth), meta);
      }
    }
  }
}

class TreeView<T> extends StatelessWidget {
  /// The controller used to provide data and extract hierarchical information
  /// from the data items. Also used to track expanded/collapsed items.
  final TreeController<T> controller;

  /// Should the first line to the far left be drawn?
  final bool showFirstLine;

  /// Set this to true to hide all lines.
  final bool hideLines;

  /// The height of a row in the tree.
  final double itemHeight;

  /// The size of the expander and icons used in the tree. This affects some
  /// margins as they are inherently required to match such that lines line up.
  final Size iconSize;

  /// The color of the vertical and horizontal lines drawn to give the tree
  /// visual structure.
  final Color lineColor;

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
  final TreeViewBackgroundBuilder<T> backgroundBuilder;

  /// The dash pattern used to draw the property lines.
  ///
  /// ![](https://rive-app.github.io/assets-for-api-docs/assets/tree-widget-flutter/tree_property.png)
  final List<double> propertyDashPattern;

  /// Indentation is defined by [iconSize.width] + padIndent. Each new depth of
  /// the tree will offset to the right by this accumulated amount.
  final double padIndent;

  /// The margin subtracted from the total indentation when drawing the
  /// horizontal lines to the icons. This provides a little bit of padding to
  /// the icon.
  ///
  /// ![](https://rive-app.github.io/assets-for-api-docs/assets/tree-widget-flutter/icon_margin.png)
  final double iconMargin;

  /// Internal padding for the ListView in this TreeView.
  final EdgeInsetsGeometry padding;

  const TreeView({
    @required this.controller,
    @required this.expanderBuilder,
    @required this.iconBuilder,
    @required this.itemBuilder,
    this.extraBuilder,
    this.backgroundBuilder,
    this.showFirstLine = false,
    this.hideLines = false,
    this.itemHeight = 35,
    this.iconSize = const Size(15, 15),
    this.lineColor = Colors.black,
    this.propertyDashPattern = const [3.0, 2.0],
    this.padIndent = 10,
    this.iconMargin = 5,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TreeController<T>>.value(
      value: controller,
      child: Consumer<TreeController<T>>(
        builder: (context, controller, _) => Scrollbar(
          child: ListView.custom(
            // semanticChildCount: controller.flat.length,
            padding: padding,
            childrenDelegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                var item = controller.flat[index];
                var lines = <Widget>[];
                int depthCount = item.depth.length;
                bool hasChildren = item.hasChildren;
                int numberOfLines = hasChildren ? depthCount - 1 : depthCount;
                bool shortLastLine = !hasChildren && item.isLastChild;
                numberOfLines--;
                double toLineCenter = iconSize.width / 2;
                double offset = toLineCenter; // 20 + toLineCenter;
                double indent = iconSize.width + padIndent;
                bool showLines = !hideLines;
                // TODO: Fix this later.
                int dragDepth = item.dragDepth ?? 255;
                for (var i = 0; i < numberOfLines; i++) {
                  double opacity = 1.0;
                  var d = item.depth[i];
                  offset += indent * (d.abs() - 1);
                  if (d > 0) {
                    // var style = {left:px(offset)};
                    if (i >= dragDepth || item.isDisabled) {
                      //style.opacity = DragOpacity;
                      opacity = 0.5;
                    }

                    // verticalLines.add(<div key={i} className={styles.Line} style={style}></div>);
                    lines.add(
                      Positioned(
                        left: offset,
                        child: Container(
                          width: 1,
                          height: itemHeight,
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
                    numberOfLines < item.depth.length && numberOfLines > 0
                        ? item.depth[numberOfLines]
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
                    opacity = 0.5;
                    // style.opacity = DragOpacity;
                  }
                  // verticalLines.push(<div className={lastLineStyle} key={numberOfLines} style={style}></div>);
                  lines.add(
                    Positioned(
                      left: offset,
                      top: top,
                      bottom: bottom,
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
                for (final s in item.depth) {
                  spaces += s.abs();
                }
                double spaceLeft = spaces * indent;

                var dashing = item.isProperty ? propertyDashPattern : null;

                bool showOurLine = item.depth[item.depth.length - 1] != -1;

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

                double dragOpacity = dragging || item.isDisabled ? 0.5 : 1.0;
                double aboveDragOpacity =
                    dragging && prevDragDepth != null ? 0.5 : 1.0;
                double belowDragOpacity =
                    numberOfLines + 1 >= dragDepth && nextDragDepth != null
                        ? 0.5
                        : 1.0;

                if (hasChildren) {
                  if (showLines && showOurLine && index != 0) {
                    // Example: Red connector above expander: https://cl.ly/0Z452u3b3S1z
                    // <div className={styles.ConnectorLine} style={{height:px((rowHeight-iconSize)/2), top:px(-(rowHeight-iconSize)/2-1), bottom:"initial", opacity:aboveDragOpacity}}></div>}
                    lines.insert(
                      0,
                      Positioned(
                        left: spaceLeft + iconSize.width / 2,
                        top: 0,
                        child: Container(
                          width: 1,
                          height: (itemHeight - iconSize.height) / 2,
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
                    if (showLines && showOurLine && !item.isLastChild) {
                      // Example: Red connector under expander: https://cl.ly/473J3m462g0e
                      lines.insert(
                        0,
                        Positioned(
                          left: spaceLeft + iconSize.width / 2,
                          top: itemHeight / 2 + iconSize.height / 2,
                          child: Container(
                            width: 1,
                            // extra 0.5 here to avoid precision errors leaving a
                            // gap
                            height: (itemHeight - iconSize.height) / 2 + 1.5,
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
                  }
                } else if (!(item.depth.length == 1 && item.depth[0] == -1)) {
                  //(this.props.hideFirstHorizontalLine && depth.length === 1 && depth[0] === -1) ? null : <div className={horizontalLineStyle} style={{background:showOurLine && showLines ? null : "initial", opacity:dragOpacity}}></div>
                  lines.insert(
                    0,
                    Positioned(
                      left: spaceLeft + iconSize.width / 2,
                      top: itemHeight / 2,
                      child: Container(
                        width: iconSize.width / 2 + padIndent - iconMargin,
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
                      left: spaceLeft +
                          (item.spacing * indent) +
                          iconSize.width / 2,
                      top: itemHeight / 2 + iconSize.height / 2 + 0.5,
                      child: Container(
                        width: 1,
                        height: (itemHeight - iconSize.height) / 2 + 1.5,
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
                  var value = backgroundBuilder(
                      context, item, indent + spaceLeft - iconMargin);
                  if (value != null) {
                    lines.add(value);
                    // Draw background before lines?
                    //lines.insert(0, value);
                  }
                }
                // print("REBUILD ${item.data}");
                //var controller = Provider.of<TreeController<T>>(context);
                return Container(
                  key: item.key,
                  height: itemHeight,
                  child: Stack(
                    children: <Widget>[
                      Stack(children: lines),
                      Positioned(
                        left: spaceLeft,
                        right: 0,
                        top: 0,
                        bottom: 0,
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
                                      height: iconSize.height,
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
                                padding: EdgeInsets.only(right: padIndent),
                                width: indent,
                                height: iconSize.height,
                                child: extraBuilder?.call(context, item, i),
                              ),
                            Container(
                              padding: EdgeInsets.only(right: padIndent),
                              width: indent,
                              height: iconSize.height,
                              child: IgnorePointer(
                                child: iconBuilder(context, item),
                              ),
                            ),
                            itemBuilder(context, item),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: controller.flat.length,
              findChildIndexCallback: (Key key) {
                // controller.lookup[]
                //print("KEY $key ${controller._indexLookup[key]}");
                return controller._indexLookup[key];
                // int idx = controller.flat.indexWhere((item) => item.key == key);
                // return idx == -1 ? null : idx;
              },
              // addRepaintBoundaries: false,
              // addAutomaticKeepAlives: true,
            ),
          ),
        ),
      ),
    );
  }
}
