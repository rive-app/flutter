import 'package:flutter/widgets.dart';
import 'package:utilities/platform.dart';
import 'package:tree_widget/tree_scroll_view.dart';

class RiveTreeView extends StatefulWidget {
  final EdgeInsets padding;
  final List<Widget> slivers;
  final ScrollController scrollController;
  final Key center;
  final ScrollPhysics physics;
  const RiveTreeView({
    Key key,
    this.padding,
    this.slivers,
    this.scrollController,
    this.center,
    this.physics,
  }) : super(key: key);

  @override
  _RiveTreeState createState() => _RiveTreeState();
}

class _RiveTreeState extends State<RiveTreeView> {
  ScrollController _controller;
  @override
  void initState() {
    super.initState();
    _updateScrollController();
  }

  @override
  void didUpdateWidget(RiveTreeView oldWidget) {
    _updateScrollController();
    super.didUpdateWidget(oldWidget);
  }

  void _updateScrollController() {
    if (widget.scrollController == null) {
      _controller ??= ScrollController();
    } else {
      _controller = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TreeScrollView(
      padding: widget.padding,
      slivers: widget.slivers,
      scrollController: _controller ?? widget.scrollController,
      center: widget.center,
      physics: widget.physics ??
          (Platform.instance.isTouchDevice
              // use default scroll physics for touch device
              ? null
              // use no scroll physics on desktop
              : const NeverScrollableScrollPhysics()),
    );
  }
}
// class TreeScrollView extends StatelessWidget {
//   final EdgeInsets padding;
//   final List<Widget> slivers;
//   final ScrollController scrollController;
//   final Key center;
//   final ScrollPhysics physics;
//   const TreeScrollView({
//     Key key,
//     this.padding,
//     this.slivers,
//     this.scrollController,
//     this.center,
//     this.physics,
//   }) : super(key: key);
