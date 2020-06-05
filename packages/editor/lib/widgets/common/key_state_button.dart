import 'package:core/key_state.dart';
import 'package:cursor/propagating_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/animation/key_path_maker.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/theme.dart';

class KeyStateButton extends StatelessWidget {
  final KeyState keyState;
  final void Function() setKey;

  const KeyStateButton({
    Key key,
    this.keyState,
    this.setKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PropagatingListener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (details) => setKey(),
      child: KeyStateRenderer(
        keyState: keyState,
        theme: RiveTheme.of(context),
      ),
    );
  }
}

@immutable
class KeyStateRenderer extends LeafRenderObjectWidget {
  final KeyState keyState;
  final RiveThemeData theme;

  const KeyStateRenderer({
    @required this.keyState,
    @required this.theme,
  });
  @override
  RenderObject createRenderObject(BuildContext context) {
    return KeyStateRenderBox()
      ..keyState = keyState
      ..theme = theme;
  }

  @override
  void updateRenderObject(
      BuildContext context, KeyStateRenderBox renderObject) {
    renderObject
      ..keyState = keyState
      ..theme = theme;
  }
}

class KeyStateRenderBox extends RenderBox {
  final Path fillPath = Path();
  final Path strokePath = Path();
  final Paint none = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = false;
  final Paint keyframe = Paint()..isAntiAlias = false;
  final Paint interpolated = Paint()
    ..style = PaintingStyle.stroke
    ..isAntiAlias = false;

  RiveThemeData _theme;
  RiveThemeData get theme => _theme;
  set theme(RiveThemeData value) {
    if (value == _theme) {
      return;
    }
    _theme = value;
    markNeedsPaint();

    var keySize = theme.dimensions.keySize;
    var halfKeySize = keySize / 2;

    makeStrokeKeyPath(strokePath, _theme,
        Offset(halfKeySize.floorToDouble() + 1, halfKeySize.floorToDouble()));
    makeFillKeyPath(fillPath, _theme,
        Offset(halfKeySize.floorToDouble() + 1, halfKeySize.floorToDouble()));
    none.color = _theme.colors.keyStateEmpty;
    keyframe.color = _theme.colors.key;
    interpolated.color = _theme.colors.key;

    none.strokeWidth = interpolated.strokeWidth = 1;
  }

  KeyState _keyState;
  KeyState get keyState => _keyState;
  set keyState(KeyState value) {
    if (value == _keyState) {
      return;
    }
    _keyState = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    var keySize = theme.dimensions.keySize;
    size = Size(keySize + 2, keySize);
  }

  @override
  bool get sizedByParent => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    var canvas = context.canvas;
    Paint paint;
    Path path;
    switch (_keyState) {
      case KeyState.none:
        paint = none;
        path = strokePath;
        break;
      case KeyState.keyframe:
        paint = keyframe;
        path = fillPath;
        break;
      case KeyState.interpolated:
        paint = interpolated;
        path = strokePath;
        break;
    }
    if (paint == null) {
      return;
    }
    var x = offset.dx.roundToDouble();
    var y = offset.dy.roundToDouble();

    canvas.translate(x, y);
    canvas.drawPath(path, paint);
    canvas.translate(-x, -y);
  }
}
