import 'package:flutter/widgets.dart';

class InspectorRadioButton extends StatelessWidget {
  static const double radius = 20;
  final bool isSelected;
  final VoidCallback select;
  const InspectorRadioButton({Key key, this.isSelected, this.select})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius,
      height: radius,
      child: GestureDetector(
        onTap: select,
        child: CustomPaint(
          painter: _RadioPainter(isSelected),
        ),
      ),
    );
  }
}

class _RadioPainter extends CustomPainter {
  final bool isSelected;

  _RadioPainter(this.isSelected);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(size.center(Offset.zero), size.width / 2,
        Paint()..color = const Color(0xFF252525));
    if (isSelected) {
      print('R: ${(size.width / 2) * 0.4}');
      canvas.drawCircle(size.center(Offset.zero), (size.width / 2) * 0.4,
          Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
