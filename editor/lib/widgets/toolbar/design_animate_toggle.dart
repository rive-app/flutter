import 'package:flutter/material.dart';

const kAnimateToggleWidth = 197.0;

class DesignAnimateToggle extends StatefulWidget {
  @override
  _DesignAnimateToggleState createState() => _DesignAnimateToggleState();
}

class _DesignAnimateToggleState extends State<DesignAnimateToggle> {
  bool isAnimate = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: kAnimateToggleWidth,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color.fromRGBO(47, 47, 47, 1.0),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            top: 0,
            bottom: 0,
            curve: Curves.easeIn,
            left: isAnimate ? null : 0,
            right: !isAnimate ? null : 0,
            width: kAnimateToggleWidth / 2,
            child: Container(
              width: kAnimateToggleWidth / 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: const Color.fromRGBO(68, 68, 68, 1.0),
              ),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            left: 0,
            width: kAnimateToggleWidth / 2,
            child: GestureDetector(
              onTap: () => _setAnimate(false),
              child: _buildText('Design', !isAnimate),
            ),
          ),
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            width: kAnimateToggleWidth / 2,
            child: GestureDetector(
              onTap: () => _setAnimate(true),
              child: _buildText('Animate', isAnimate),
            ),
          ),
        ],
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
    if (mounted) setState(() => isAnimate = value);
  }
}
