import 'package:flutter/material.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// How to position the icon when actually rendered to layer pixels.
enum TintedIconPosition {
  actual,
  round,
  ceil,
  floor,
}

/// Draws an icon tinted by [color].
class TintedIcon extends StatelessWidget {
  final Color color;
  final String icon;
  final TintedIconPosition position;

  const TintedIcon({
    @required this.color,
    @required this.icon,
    this.position = TintedIconPosition.actual,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var cache = IconCache.of(context);
    return TintedIconRenderer(
      cache: cache,
      filename: 'assets/images/icons/$icon.png',
      color: color,
      position: position,
    );
  }
}

/// Draws an image with custom paint.
class TintedIconRenderer extends LeafRenderObjectWidget {
  final String filename;
  final RiveIconCache cache;
  final Color color;
  final TintedIconPosition position;

  const TintedIconRenderer({
    @required this.filename,
    @required this.cache,
    this.position,
    this.color,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TintedIconRendererObject()
      ..filename = filename
      ..cache = cache
      ..color = color
      ..position = position;
  }

  @override
  void didUnmountRenderObject(
      covariant _TintedIconRendererObject renderObject) {
    // Any cleanup to do here?
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _TintedIconRendererObject renderObject) {
    renderObject
      ..filename = filename
      ..cache = cache
      ..color = color
      ..position = position;
  }
}

class _TintedIconRendererObject extends RenderBox {
  TintedIconPosition _position;
  String _filename;
  RiveIconCache _cache;
  Color _color;
  final Paint _paint = Paint()..isAntiAlias = false;

  TintedIconPosition get position => _position;
  set position(TintedIconPosition value) {
    if (_position == value) {
      return;
    }
    _position = value;
    markNeedsPaint();
  }

  CachedImage _cachedImage;
  RiveIconCache get cache => _cache;

  set cache(RiveIconCache value) {
    if (_cache == value) {
      return;
    }
    _cache = value;
    _load();
  }

  Color get color => _color;

  set color(Color value) {
    if (_color == value) {
      return;
    }
    _color = value;
    // Don't use a filter if the color is intentionally null.
    _paint.colorFilter =
        value == null ? null : ColorFilter.mode(value, BlendMode.srcIn);
    markNeedsPaint();
  }

  String get filename => _filename;

  set filename(String value) {
    if (_filename == value) {
      return;
    }
    _filename = value;
    _load();
  }

  @override
  bool get sizedByParent => false;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_cachedImage == null) {
      return;
    }
    var canvas = context.canvas;
    var image = _cachedImage.image;

    Offset renderOffset;
    switch (_position) {
      case TintedIconPosition.ceil:
        print("CEILING: ${offset.dy} ${offset.dy.ceilToDouble()}");
        renderOffset =
            Offset(offset.dx.ceilToDouble(), offset.dy.ceilToDouble());
        break;
      case TintedIconPosition.floor:
        renderOffset =
            Offset(offset.dx.floorToDouble(), offset.dy.floorToDouble());
        break;
      case TintedIconPosition.round:
        renderOffset =
            Offset(offset.dx.roundToDouble(), offset.dy.roundToDouble());
        break;
      case TintedIconPosition.actual:
      default:
        renderOffset = offset;
        break;
    }
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        renderOffset & size,
        _paint);
  }

  @override
  void performLayout() {
    size = constraints.constrain(_cachedImage == null
        ? Size.zero
        : Size(_cachedImage.image.width.toDouble() / _cachedImage.resolution,
            _cachedImage.image.height.toDouble() / _cachedImage.resolution));
  }

  void _load() {
    if (_cache == null) {
      return;
    }
    var cachedImage = _cache.image(_filename);
    if (cachedImage == null) {
      // Not in the cache, load it up.
      _cache.load(filename).then((cachedImage) {
        _cachedImage = cachedImage;
        markNeedsLayout();
      });
    } else if (cachedImage.completer.isCompleted) {
      // In the cache and ready to go.
      _cachedImage = cachedImage;
      markNeedsLayout();
    } else {
      // In the cache but not done loading, wait for it to be ready.
      cachedImage.completer.future.then((_) {
        _cachedImage = cachedImage;
        markNeedsLayout();
      });
    }
  }
}
