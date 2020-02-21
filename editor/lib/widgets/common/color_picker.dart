import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class RiveColorPicker extends StatefulWidget {
  @override
  _RiveColorPickerState createState() => _RiveColorPickerState();
}

class _RiveColorPickerState extends State<RiveColorPicker> {
  Color _color = Colors.red;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210.0,
      decoration: BoxDecoration(
          color: const Color(0XFF262626),
          borderRadius: BorderRadius.circular(10)),
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 50.0,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(decoration: InputDecoration(),),
                  ),
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: const TintedIcon(
                      color: Color(0xFF8C8C8C),
                      icon: 'tool-node',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 153,
              width: 210.0,
              child: ColorPickerArea(
                color: _color,
                onChanged: _changeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeColor(Color value) {
    if (mounted) {
      setState(() {
        _color = value;
      });
    }
  }
}

class ColorPickerArea extends StatelessWidget {
  const ColorPickerArea({
    @required this.color,
    @required this.onChanged,
  });

  final Color color;
  final ValueChanged<Color> onChanged;

  void _handleColorChange(double horizontal, double vertical) {
    final hsvColor = HSVColor.fromColor(color);
    final _color = hsvColor.withSaturation(horizontal).withValue(vertical);
    onChanged(_color.toColor());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double width = constraints.maxWidth;
        double height = constraints.maxHeight;

        return GestureDetector(
          onPanDown: (DragDownDetails details) {
            RenderBox getBox = context.findRenderObject() as RenderBox;
            Offset localOffset = getBox.globalToLocal(details.globalPosition);
            double horizontal = localOffset.dx.clamp(0.0, width) / width;
            double vertical = 1 - localOffset.dy.clamp(0.0, height) / height;
            _handleColorChange(horizontal, vertical);
          },
          onPanUpdate: (DragUpdateDetails details) {
            RenderBox getBox = context.findRenderObject() as RenderBox;
            Offset localOffset = getBox.globalToLocal(details.globalPosition);
            double horizontal = localOffset.dx.clamp(0.0, width) / width;
            double vertical = 1 - localOffset.dy.clamp(0.0, height) / height;
            _handleColorChange(horizontal, vertical);
          },
          child: Builder(
            builder: (BuildContext _) {
              return CustomPaint(
                painter: HSVColorPainter(color),
              );
            },
          ),
        );
      },
    );
  }
}

class HSVColorPainter extends CustomPainter {
  const HSVColorPainter(this.color, {this.pointerColor});

  final Color color;
  final Color pointerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final hsvColor = HSVColor.fromColor(color);
    final Rect rect = Offset.zero & size;
    final Gradient gradientV = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Colors.black],
    );
    final Gradient gradientH = LinearGradient(
      colors: [
        Colors.white,
        HSVColor.fromAHSV(1.0, hsvColor.hue, 1.0, 1.0).toColor(),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradientV.createShader(rect));
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.multiply
        ..shader = gradientH.createShader(rect),
    );

    canvas.drawCircle(
      Offset(
          size.width * hsvColor.saturation, size.height * (1 - hsvColor.value)),
      size.height * 0.04,
      Paint()
        ..color = (pointerColor ??
            (useWhiteForeground(hsvColor.toColor())
                ? Colors.white
                : Colors.black))
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

bool useWhiteForeground(Color color, {double bias: 1.0}) {
  bias ??= 1.0;
  int v = sqrt(pow(color.red, 2) * 0.299 +
          pow(color.green, 2) * 0.587 +
          pow(color.blue, 2) * 0.114)
      .round() as int;
  return v < 130 * bias ? true : false;
}

HSLColor hsvToHsl(HSVColor color) {
  double s = 0.0;
  double l = 0.0;
  l = (2 - color.saturation) * color.value / 2;
  if (l != 0) {
    if (l == 1)
      s = 0.0;
    else if (l < 0.5)
      s = color.saturation * color.value / (l * 2);
    else
      s = color.saturation * color.value / (2 - l * 2);
  }
  return HSLColor.fromAHSL(
    color.alpha,
    color.hue,
    s.clamp(0.0, 1.0).toDouble(),
    l.clamp(0.0, 1.0).toDouble(),
  );
}

HSVColor hslToHsv(HSLColor color) {
  double s = 0.0;
  double v = 0.0;

  v = color.lightness +
      color.saturation *
          (color.lightness < 0.5 ? color.lightness : 1 - color.lightness);
  if (v != 0) s = 2 - 2 * color.lightness / v;

  return HSVColor.fromAHSV(
    color.alpha,
    color.hue,
    s.clamp(0.0, 1.0).toDouble(),
    v.clamp(0.0, 1.0).toDouble(),
  );
}
