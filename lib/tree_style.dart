import 'dart:ui';
import 'package:flutter/material.dart';

/// Immutable styling for a TreeView.
class TreeStyle {
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

  /// Opacity applied to items that are being dragged or disabled.
  final double inactiveOpacity;

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

  const TreeStyle({
    this.showFirstLine = false,
    this.hideLines = false,
    this.itemHeight = 35,
    this.iconSize = const Size(15, 15),
    this.lineColor = Colors.black,
    this.propertyDashPattern = const [3.0, 2.0],
    this.padIndent = 5,
    this.iconMargin = 5,
    this.inactiveOpacity = 0.28,
    this.padding,
  });
}

const TreeStyle defaultTreeStyle = TreeStyle();
