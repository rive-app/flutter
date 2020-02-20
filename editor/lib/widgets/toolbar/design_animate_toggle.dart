import 'package:flutter/material.dart';

const kAnimateToggleWidth = 197.0;

class DesignAnimateToggle extends StatefulWidget {
  @override
  _DesignAnimateToggleState createState() => _DesignAnimateToggleState();
}

class _DesignAnimateToggleState extends State<DesignAnimateToggle>
    with SingleTickerProviderStateMixin {
  bool isAnimate = false;
  AnimationController controller;
  Animation<double> animation;

  @override
  void initState() {
    const _duration = Duration(milliseconds: 100);
    controller = AnimationController(
      vsync: this,
      duration: _duration,
      reverseDuration: _duration,
    );
    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );
    animation = Tween<double>(
      begin: 0,
      end: kAnimateToggleWidth / 2,
    ).animate(curve)
      ..addListener(() => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kAnimateToggleWidth,
      child: LayoutBuilder(
        builder: (_, dimens) => Stack(
          children: <Widget>[
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: const Color.fromRGBO(47, 47, 47, 1.0),
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: animation.value,
              width: kAnimateToggleWidth / 2,
              child: Container(
                margin: const EdgeInsets.all(1.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: const Color.fromRGBO(68, 68, 68, 1.0),
                ),
              ),
            ),
            Positioned(
              left: 0,
              width: kAnimateToggleWidth / 2,
              height: dimens.maxHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _setAnimate(false),
                child: _buildText('Design', !isAnimate),
              ),
            ),
            Positioned(
              right: 0,
              width: kAnimateToggleWidth / 2,
              height: dimens.maxHeight,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => _setAnimate(true),
                child: _buildText('Animate', isAnimate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildText(String text, bool selected) {
    return Center(
      child: Text(
        text,
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  void _setAnimate(bool value) {
    isAnimate = value;
    // if (mounted) setState(() => isAnimate = value);
    if (isAnimate) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }
}
