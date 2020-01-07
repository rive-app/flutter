import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'system_cursor.dart';

typedef CursorBuilder = Widget Function(BuildContext context);

class Cursor extends ChangeNotifier {
  CursorBuilder _builder;

  void _change(CursorBuilder builder) {
    if (_builder == builder) {
      return;
    }
    _builder = builder;
    if (_builder == null) {
      SystemCursor.show();
    } else {
      SystemCursor.hide();
    }
    notifyListeners();
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
      child: Listener(
        onPointerMove: (details) {
          setState(() {
            // print("POS $_position");
            _position = details.position;
          });
        },
        onPointerHover: (details) {
          setState(() {
            // print("POS $_position");
            _position = details.position;
          });
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: widget.child,
            ),
            Consumer<Cursor>(
              builder: (context, state, widget) {
                var child = state?._builder?.call(context);
                if (child != null) {
                  return Positioned(
                      left: _position.dx, top: _position.dy, child: child);
                } else {
                  return nullCursor;
                }
              },
            ),
          ].where((item) => item != nullCursor).toList(growable: false),
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
