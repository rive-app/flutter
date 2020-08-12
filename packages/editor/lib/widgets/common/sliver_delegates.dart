import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SliverGridDelegateFixedSize extends SliverGridDelegate {
  /// Creates a delegate that makes grid layouts with fixed tile
  /// sizing.
  ///
  /// All of the arguments must not be null or negative. The `mainAxisSpacing` and
  /// `crossAxisSpacing` arguments must not be negative. The `crossAxisExtent`
  /// and `mainAxisExtent` arguments must be greater than zero.
  const SliverGridDelegateFixedSize({
    @required this.crossAxisExtent,
    @required this.mainAxisExtent,
    this.mainAxisSpacing = 0.0,
    this.crossAxisSpacing = 0.0,
  })  : assert(crossAxisExtent != null && crossAxisExtent > 0),
        assert(mainAxisSpacing != null && mainAxisSpacing >= 0),
        assert(crossAxisSpacing != null && crossAxisSpacing >= 0),
        assert(mainAxisExtent != null && mainAxisExtent > 0);

  /// The extent of each child along the main axis.
  final double mainAxisExtent;

  /// The extent of each child along the cross axis.
  final double crossAxisExtent;

  /// The number of logical pixels between each child along the main axis.
  final double mainAxisSpacing;

  /// The number of logical pixels between each child along the cross axis.
  final double crossAxisSpacing;

  bool _debugAssertIsValid() {
    assert(mainAxisExtent > 0);
    assert(mainAxisSpacing >= 0.0);
    assert(crossAxisSpacing >= 0.0);
    assert(crossAxisExtent > 0.0);
    return true;
  }

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    assert(_debugAssertIsValid());
    // (count * Width) + ((count -1) * spacers) = overall Width
    // solved for count, rounded down.
    final crossAxisCount = max(
        ((constraints.crossAxisExtent + crossAxisSpacing) /
                (crossAxisExtent + crossAxisSpacing))
            .floor(),
        1);

    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: mainAxisExtent + mainAxisSpacing,
      crossAxisStride: crossAxisExtent + crossAxisSpacing,
      childMainAxisExtent: mainAxisExtent,
      childCrossAxisExtent: crossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(SliverGridDelegateFixedSize oldDelegate) {
    return oldDelegate.crossAxisExtent != crossAxisExtent ||
        oldDelegate.mainAxisSpacing != mainAxisSpacing ||
        oldDelegate.crossAxisSpacing != crossAxisSpacing ||
        oldDelegate.mainAxisExtent != mainAxisExtent;
  }
}
