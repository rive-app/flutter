import 'package:flutter/material.dart';
import 'package:rive_editor/rive/theme.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

const kAnimateToggleWidth = 197.0;

class DesignAnimateToggle extends StatefulWidget {
  @override
  _DesignAnimateToggleState createState() => _DesignAnimateToggleState();
}

class _DesignAnimateToggleState extends State<DesignAnimateToggle>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation<double> animation;
  List<Animation<Color>> gradientColors;

  @override
  void initState() {
    const _duration = Duration(milliseconds: 300);
    final theme = RiveThemeData();
    controller = AnimationController(
      vsync: this,
      duration: _duration,
      reverseDuration: _duration,
    );
    final curve = CurvedAnimation(
      parent: controller,
      curve: const Cubic(0.8, 0, 0, 1),
    );
    animation = Tween<double>(
      begin: 0,
      end: kAnimateToggleWidth / 2,
    ).animate(curve)
      ..addListener(_update);
    gradientColors = [];
    for (final color in theme.gradients.magenta.colors) {
      gradientColors.add(ColorTween(
        begin: theme.colors.animateToggleButton,
        end: color,
      ).animate(curve));
    }
    super.initState();
  }

  void _update() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    var rive = RiveContext.of(context);
    final theme = RiveTheme.of(context);
    return Container(
      width: kAnimateToggleWidth,
      child: LayoutBuilder(
        builder: (_, dimens) => Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: const Color(0xFF2F2F2F),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: animation.value,
              width: kAnimateToggleWidth / 2,
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: theme.colors.animateToggleButton,
                  gradient: LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      for (final color in gradientColors) ...[
                        color.value,
                      ]
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              width: kAnimateToggleWidth / 2,
              height: dimens.maxHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _setAnimate(false, rive.isAnimateMode),
                child: Center(
                  child: Text(
                    'Design',
                    style: TextStyle(
                      color: controller.value <= 0.5
                          ? theme.colors.activeText
                          : theme.colors.inactiveText,
                      fontFamily: 'Roboto-Light',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              width: kAnimateToggleWidth / 2,
              height: dimens.maxHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _setAnimate(true, rive.isAnimateMode),
                child: Center(
                  child: Text(
                    'Animate',
                    style: TextStyle(
                      color: controller.value >= 0.5
                          ? theme.colors.activeText
                          : theme.colors.inactiveText,
                      fontFamily: 'Roboto-Light',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _setAnimate(bool value, ValueNotifier<bool> notifier) {
    // if (mounted) setState(() => isAnimate = value);
    if (value) {
      controller.forward();
    } else {
      controller.reverse();
    }
    notifier.value = value;
  }
}
