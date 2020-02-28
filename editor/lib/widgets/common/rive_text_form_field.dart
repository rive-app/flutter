import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'dart:math' as math;

class RiveTextFormField extends StatefulWidget {
  const RiveTextFormField({
    @required this.hintText,
    @required this.initialValue,
    this.onComplete,
    this.onChanged,
    this.edgeInsets = EdgeInsets.zero,
    Key key,
    this.borderWidth = 2,
  }) : super(key: key);

  final String hintText;
  final String initialValue;
  final ValueChanged<String> onComplete, onChanged;
  final EdgeInsets edgeInsets;
  final double borderWidth;

  @override
  _RiveTextFormFieldState createState() => _RiveTextFormFieldState();
}

class _RiveTextFormFieldState extends State<RiveTextFormField> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void initState() {
    _controller.text = widget.initialValue;
    super.initState();
  }

  @override
  void didUpdateWidget(RiveTextFormField oldWidget) {
    if (oldWidget.initialValue != widget.initialValue) {
      if (widget.initialValue != _controller.text) {
        _controller.text = widget.initialValue;
      }
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: TextFormField(
        controller: _controller,
        textAlignVertical: TextAlignVertical.top,
        scrollPadding: EdgeInsets.zero,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: widget.edgeInsets,
          enabledBorder: CustomUnderlineBorder(
            padding: const EdgeInsets.only(top: 1),
            borderSide: BorderSide(
                width: widget.borderWidth,
                color: RiveTheme.of(context).colors.separator),
          ),
          focusedBorder: CustomUnderlineBorder(
            padding: const EdgeInsets.only(top: 1),
            borderSide: BorderSide(
              width: widget.borderWidth,
              color: RiveTheme.of(context).colors.separatorActive,
            ),
          ),
          hintText: widget.hintText,
          hintStyle: RiveTheme.of(context).textStyles.inspectorPropertyValue,
        ),
        style: RiveTheme.of(context).textStyles.inspectorPropertyValue,
        onChanged: widget.onChanged,
        onSaved: widget.onComplete,
        onEditingComplete: () {
          _formKey.currentState.save();
        },
      ),
    );
  }
}

class CustomUnderlineBorder extends InputBorder {
  const CustomUnderlineBorder({
    BorderSide borderSide = const BorderSide(),
    this.borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(4.0),
      topRight: Radius.circular(4.0),
    ),
    this.padding = EdgeInsets.zero,
  })  : assert(borderRadius != null),
        super(borderSide: borderSide);

  final BorderRadius borderRadius;
  final EdgeInsets padding;

  @override
  bool get isOutline => false;

  @override
  CustomUnderlineBorder copyWith({
    BorderSide borderSide,
    BorderRadius borderRadius,
    EdgeInsets padding,
  }) {
    return CustomUnderlineBorder(
      borderSide: borderSide ?? this.borderSide,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
    );
  }

  @override
  EdgeInsetsGeometry get dimensions {
    return EdgeInsets.only(bottom: borderSide.width).subtract(padding);
  }

  @override
  CustomUnderlineBorder scale(double t) {
    return CustomUnderlineBorder(borderSide: borderSide.scale(t));
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection textDirection}) {
    final r = Rect.fromLTWH(rect.left, rect.top, rect.width,
        math.max(0.0, rect.height - borderSide.width));
    final p = Rect.fromLTRB(r.left, r.top, r.right, r.bottom);
    return Path()..addRect(p);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection textDirection}) {
    return Path()..addRRect(borderRadius.resolve(textDirection).toRRect(rect));
  }

  @override
  ShapeBorder lerpFrom(ShapeBorder a, double t) {
    if (a is CustomUnderlineBorder) {
      return CustomUnderlineBorder(
        borderSide: BorderSide.lerp(a.borderSide, borderSide, t),
        borderRadius: BorderRadius.lerp(a.borderRadius, borderRadius, t),
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder lerpTo(ShapeBorder b, double t) {
    if (b is CustomUnderlineBorder) {
      return CustomUnderlineBorder(
        borderSide: BorderSide.lerp(borderSide, b.borderSide, t),
        borderRadius: BorderRadius.lerp(borderRadius, b.borderRadius, t),
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection textDirection,
  }) {
    final _paint = Paint();
    _paint.strokeWidth = borderSide.width;
    _paint.color = borderSide.color;
    final _rect = Rect.fromLTWH(
      rect.left,
      rect.bottom,
      rect.width,
      2,
    );
    canvas.translate(0, 0.5);
    canvas.drawRect(_rect, _paint);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is InputBorder && other.borderSide == borderSide;
  }

  @override
  int get hashCode => borderSide.hashCode;
}
