import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  void _change(CursorBuilder builder) {
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
            painter: _PathPainter(renderPath, fill, stroke, shadowPaint)));
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
    Provider.of<Cursor>(context, listen: false)._change(builder);
  }

  /// Reset the cursor to the default platform one.
  static void reset(BuildContext context) {
    Provider.of<Cursor>(context, listen: false)._change(null);
  }

  /// Check if the cursor matches some [builder].
  void matches(CursorBuilder builder) => _builder == builder;
}

class CursorView extends StatefulWidget {
  final Widget child;

  const CursorView({Key key, this.child}) : super(key: key);

  @override
  _CursorViewState createState() => _CursorViewState();
}

class _CursorViewState extends State<CursorView> {
  Offset _position = Offset.zero;
  Cursor _cursor = Cursor();
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<Cursor>.value(
      value: _cursor,
      child: MouseRegion(
        opaque: false,
        onHover: (details) {
          setState(() {
            _position = details.position;
          });
        },
        child: Listener(
          behavior: HitTestBehavior.deferToChild,
          onPointerMove: (details) {
            setState(() {
              // print("POS $_position");
              _position = details.position;
            });
          },
          child: Stack(
        textDirection: TextDirection.ltr,
            children: [
              Positioned.fill(
                child: widget.child,
              ),
              Consumer<Cursor>(
                builder: (context, state, widget) {
                  var child = state?._builder?.call(context);
                  if (child != null) {
                    return Positioned(
                      left: _position.dx,
                      top: _position.dy,
                      child: IgnorePointer(child: child),
                    );
                  } else {
                    return nullCursor;
                  }
                },
              ),
            ].where((item) => item != nullCursor).toList(growable: false),
          ),
        ),
      ),
    );
  }
}

class NullCursor extends StatelessWidget {
  const NullCursor();
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

const nullCursor = NullCursor();
