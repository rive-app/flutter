import 'dart:typed_data';

import 'package:cursor/propagating_listener.dart';
import 'package:flutter/material.dart';

import 'system_cursor.dart';

typedef CursorBuilder = Widget Function(BuildContext context);

class _PathPainter extends CustomPainter {
  _PathPainter(this.path, this.fill, this.stroke, this.shadow);

  final Path path;
  final Paint fill;
  final Paint shadow;
  final Paint stroke;

  @override
  bool shouldRepaint(_PathPainter oldDelegate) => true;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(2, 5);
    canvas.drawPath(path, shadow);
    canvas.restore();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }
}

class Cursor extends ChangeNotifier {
  CursorBuilder _builder;
  bool _isShowing = true;

  void withBuilder(CursorBuilder builder) {
    if (_builder == builder) {
      return;
    }
    _builder = builder;

    var show = _builder == null;
    if (_isShowing != show) {
      _isShowing = show;
      if (show) {
        SystemCursor.show();
      } else {
        SystemCursor.hide();
      }
    }

    notifyListeners();
  }

  /// Show the default cursor if we were hiding it.
  void show() {
    if (_builder == _emptyBuilder) {
      withBuilder(null);
    }
  }

  /// Hide the cursor.
  void hide() => withBuilder(_emptyBuilder);

  bool get isCustom => _builder != null;
  bool get isHidden => _builder == _emptyBuilder;

  Widget _emptyBuilder(BuildContext context) => const SizedBox();

  static var shadowPaint = Paint()
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0)
    ..color = Colors.black.withOpacity(0.4);

  static void path(BuildContext context, Path path, Offset translate,
      double scale, Paint fill, Paint stroke) {
    Float64List transform = Float64List.fromList([
      scale,
      0,
      0,
      0,
      0,
      scale,
      0,
      0,
      0,
      0,
      1,
      0,
      translate.dx,
      translate.dy,
      0,
      1,
    ]);
    Path renderPath = path.transform(transform);
    change(
      context,
      (context) => CustomPaint(
        painter: _PathPainter(renderPath, fill, stroke, shadowPaint),
      ),
    );
  }

  static void pathBlack(
      BuildContext context, Path path, Offset translate, double scale) {
    Cursor.path(
        context,
        path,
        translate,
        scale,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill
          ..isAntiAlias = false,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..isAntiAlias = false);
  }

  static void pathWhite(
      BuildContext context, Path path, Offset translate, double scale) {
    Cursor.path(
        context,
        path,
        translate,
        scale,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  /// Use a custom [builder] to make your own cursor.
  static void change(BuildContext context, CursorBuilder builder) {
    CustomCursor.find(context).withBuilder(builder);
  }

  /// Reset the cursor to the default platform one.
  static void reset(BuildContext context) {
    CustomCursor.find(context).withBuilder(null);
  }

  /// Check if the cursor matches some [builder].
  void matches(CursorBuilder builder) => _builder == builder;
}

/// Easy way to grab the active file from the context.
class CustomCursor extends InheritedWidget {
  const CustomCursor({
    @required this.cursor,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final Cursor cursor;

  static Cursor of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CustomCursor>().cursor;

  static Cursor find(BuildContext context) =>
      context.findAncestorWidgetOfExactType<CustomCursor>().cursor;

  @override
  bool updateShouldNotify(CustomCursor old) => cursor != old.cursor;
}

class CursorView extends StatefulWidget {
  final Widget child;
  final PropagatingPointerDownEventListener onPointerDown;
  final PropagatingPointerUpEventListener onPointerUp;

  const CursorView({
    Key key,
    this.child,
    this.onPointerDown,
    this.onPointerUp,
  }) : super(key: key);

  @override
  _CursorViewState createState() => _CursorViewState();
}

class _CursorViewState extends State<CursorView> {
  Offset _position = Offset.zero;
  final Cursor _cursor = Cursor();

  @override
  Widget build(BuildContext context) {
    return CustomCursor(
      cursor: _cursor,
      child: MouseRegion(
        opaque: false,
        onHover: (details) {
          setState(() {
            _position = details.position;
          });
        },
        child: PropagatingListenerRoot(
          child: PropagatingListener(
            behavior: HitTestBehavior.deferToChild,
            onPointerMove: (details) {
              setState(() {
                // print("POS $_position");
                _position = details.pointerEvent.position;
              });
            },
            onPointerDown: widget.onPointerDown,
            onPointerUp: widget.onPointerUp,
            child: Stack(
              textDirection: TextDirection.ltr,
              children: [
                Positioned.fill(
                  child: widget.child,
                ),
                _ActualCursor(
                  position: _position,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActualCursor extends StatelessWidget {
  final Offset position;

  const _ActualCursor({Key key, this.position}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var cursor = CustomCursor.of(context);
    var child = cursor?._builder?.call(context);
    if (child != null) {
      return Positioned(
        left: position.dx,
        top: position.dy,
        child: IgnorePointer(child: child),
      );
    } else {
      return SizedBox();
    }
  }
}
