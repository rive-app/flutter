import 'package:flutter/material.dart';

/// Widget that takes a factor (expected to be between 0-1) and calls back a
/// builder with the interpolated value as it animates. Useful when combined
/// with widgets like FractionalIntrinsicHeight for animating the intrinsic
/// height of a widget (allowing it to still internally resize itself).
class AnimatedFactorBuilder extends StatefulWidget {
  final double factor;
  final Widget Function(BuildContext, double, Widget) builder;
  final Widget child;

  const AnimatedFactorBuilder({
    Key key,
    this.factor,
    this.builder,
    this.child,
  }) : super(key: key);
  @override
  AnimatedFactorBuilderState createState() => AnimatedFactorBuilderState();
}

class AnimatedFactorBuilderState extends State<AnimatedFactorBuilder>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  double _animatedFactor = 0;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    controller.value = _animatedFactor;
    controller.addListener(_updateAnimatedFactor);
    if (_animatedFactor != widget.factor) {
      controller.animateTo(widget.factor);
    }
  }

  void _updateAnimatedFactor() {
    setState(() {
      _animatedFactor = Curves.easeInOut.transform(controller.value);
    });
  }

  @override
  void didUpdateWidget(AnimatedFactorBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.factor != widget.factor) {
      controller.animateTo(widget.factor);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context, _animatedFactor, widget.child);
  }
}
