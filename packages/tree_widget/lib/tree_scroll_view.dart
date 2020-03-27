import 'package:flutter/material.dart';
import 'package:tree_widget/tree_style.dart';

/// Helper to build a scrollview for a tree composed with a list of slivers.
/// Automatically adds the top and bottom padding from the tree style.
class TreeScrollView extends StatelessWidget {
  final TreeStyle style;
  final List<Widget> slivers;
  final ScrollController scrollController;
  const TreeScrollView({
    Key key,
    this.style,
    this.slivers,
    this.scrollController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      child: CustomScrollView(
        controller: scrollController,
        
        // This keeps things highly performant, we don't want any overdraw.
        // Flutter uses this for semantics to give feedback on what's offscreen,
        // but for now we can optimize this out.
        cacheExtent: 0,
        slivers: [
          // Add top padding (can't use Sliver padding, as using one with empty
          // sliver causes bugs with virtualization).
          SliverToBoxAdapter(child: SizedBox(height: style.padding.top)),

          ...slivers,

          // Add top padding (can't use Sliver padding, as using one with empty
          // sliver causes bugs with virtualization).
          SliverToBoxAdapter(child: SizedBox(height: style.padding.top)),
        ],
      ),
    );
  }
}
