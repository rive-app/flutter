import 'dart:math';
import 'dart:ui';

import 'package:rive_api/user.dart';
import 'package:rive_core/client_side_player.dart';
import 'package:rive_core/math/aabb.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/stage/advancer.dart';
import 'package:rive_editor/widgets/theme.dart';

import '../stage.dart';
import '../stage_item.dart';

class StageCursor extends StageItem<ClientSidePlayer>
    with ClientSidePlayerDelegate, Advancer {
  // TODO: pick the right color palette based on Guido's input
  static List<Color> playerColors = [
    RiveThemeData().colors.cursorGreen,
    RiveThemeData().colors.cursorRed,
    RiveThemeData().colors.cursoYellow,
    RiveThemeData().colors.cursorBlue,
  ];

  static Color colorFromPalette(int index) =>
      playerColors[index % playerColors.length];

  AABB _aabb;
  Color _color;

  CachedImage _cursorImage;
  CachedImage _cursorFillImage;
  final Paint _paint = Paint()..isAntiAlias = false;
  final Paint _tintPaint = Paint()..isAntiAlias = false;

  Paragraph _nameParagraph;
  Size _nameParagraphSize;

  static const Size size = Size(10, 10);

  double _x = 0, _y = 0;

  /// Cursor is initially invisible until we receive the first move event.
  bool _isVisible = false;

  @override
  bool get isVisible => _isVisible;

  @override
  bool get isSelectable => false;

  @override
  int get drawOrder => 2;

  @override
  bool initialize(ClientSidePlayer object) {
    if (!super.initialize(object)) {
      return false;
    }
    updateBounds();
    return true;
  }

  @override
  void addedToStage(Stage stage) {
    super.addedToStage(stage);

    const String filename = 'assets/images/icons/cursor.png';
    const String filenameFill = 'assets/images/icons/cursor-fill.png';

    // Don't necessarily care about optimizing for sync case here, legibility
    // wins.
    _fromCache(filenameFill).then((image) {
      _cursorFillImage = image;
    });

    _fromCache(filename).then((image) {
      _cursorImage = image;
    });
  }

  Future<CachedImage> _fromCache(String filename) async {
    var cache = stage.rive.iconCache;
    var cachedImage = cache.image(filename);
    if (cachedImage == null) {
      return cache.load(filename);
    } else if (cachedImage.completer.isCompleted) {
      // In the cache and ready to go.
      return cachedImage;
    } else {
      // In the cache but not done loading, wait for it to be ready.
      return cachedImage.completer.future;
    }
  }

  @override
  AABB get aabb => _aabb;

  void updateBounds() {
    var cursor = component.cursor;
    _aabb =
        AABB.fromValues(_x, _y, cursor.x + size.width, cursor.y + size.height);
    stage?.updateBounds(this);
  }

  @override
  void removedFromStage(Stage stage) {
    super.removedFromStage(stage);
    stage.cancelDebounce(updateBounds);
  }

  @override
  void draw(Canvas canvas) {
    if (_cursorImage == null) {
      return;
    }
    // Hard requirement for images to be of the same size here.
    var width = _cursorImage.image.width.toDouble();
    var height = _cursorImage.image.height.toDouble();
    var scale = stage.viewZoom;
    var resolution = _cursorImage.resolution;
    var x = _x.roundToDouble();
    var y = _y.roundToDouble();

    canvas.save();
    canvas.translate(x, y);
    canvas.scale(1 / scale);

    canvas.drawImageRect(_cursorImage.image, Rect.fromLTWH(0, 0, width, height),
        Rect.fromLTWH(0, 0, width / resolution, height / resolution), _paint);
    canvas.drawImageRect(
        _cursorFillImage.image,
        Rect.fromLTWH(0, 0, width, height),
        Rect.fromLTWH(0, 0, width / resolution, height / resolution),
        _tintPaint);

    if (_nameParagraph != null) {
      var offset = Offset(0, height / resolution);
      var padding = const Size(10, 5);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(
                offset.dx,
                offset.dy,
                _nameParagraphSize.width + padding.width * 2,
                _nameParagraphSize.height + padding.height * 2,
              ),
              const Radius.circular(20)),
          Paint()..color = _color);
      canvas.drawParagraph(_nameParagraph,
          Offset(offset.dx + padding.width, offset.dy + padding.height));
    }
    canvas.restore();
  }

  @override
  void cursorChanged() {
    stage?.debounce(updateBounds);
    if (!_isVisible) {
      var cursor = component.cursor;
      _x = cursor.x;
      _y = cursor.y;
      _isVisible = true;
    }
  }

  @override
  bool advance(double elapsed) {
    var cursor = component.cursor;
    var dx = cursor.x - _x;
    var dy = cursor.y - _y;
    if (dx == 0 && dy == 0) {
      return false;
    }
    if (dx.abs() < 0.5 && dy.abs() < 0.5) {
      _x = cursor.x;
      _y = cursor.y;
      updateBounds();
      return false;
    }
    double f = min(1.0, elapsed * 10);
    _x += dx * f;
    _y += dy * f;
    updateBounds();
    return true;
  }

  @override
  void userChanged(RiveUser user, int index) {
    _color = colorFromPalette(index);
    _tintPaint.colorFilter = ColorFilter.mode(_color, BlendMode.srcIn);

    final style = ParagraphStyle(
        textAlign: TextAlign.left, fontFamily: 'Roboto-Regular', fontSize: 13);
    ParagraphBuilder builder = ParagraphBuilder(style)
      ..pushStyle(
        TextStyle(foreground: Paint()..color = const Color(0xFFFFFFFF)),
      );

    final text = user.name ?? user.username;
    builder.addText(text);
    _nameParagraph = builder.build();
    _nameParagraph.layout(const ParagraphConstraints(width: 400));
    List<TextBox> boxes = _nameParagraph.getBoxesForRange(0, text.length);
    _nameParagraphSize = boxes.isEmpty
        ? Size.zero
        : Size(boxes.last.right - boxes.first.left,
            boxes.last.bottom - boxes.first.top);
    updateBounds();
  }
}
