import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Draws an icon tinted by [color].
class TintedIcon extends StatelessWidget {
  final Color color;
  final String icon;

  const TintedIcon({Key key, this.color, this.icon}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TintedIconRenderer(
        assetBundle: rootBundle,
        filename: 'assets/images/icons/$icon.png',
        color: color,
      ),
    );
  }
}

/// Draws an image with custom paint.
class TintedIconRenderer extends LeafRenderObjectWidget {
  final String filename;
  final AssetBundle assetBundle;
  final Color color;

  const TintedIconRenderer(
      {@required this.filename, @required this.assetBundle, this.color});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _TintedIconRendererObject()
      ..filename = filename
      ..assetBundle = assetBundle
      ..color = color;
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
      ..assetBundle = assetBundle
      ..color = color;
  }
}

class _TintedIconRendererObject extends RenderBox {
  String _filename;
  AssetBundle _assetBundle;
  Color _color;
  final Paint _paint = Paint()
    ..isAntiAlias = false;

  ui.Image _image;
  AssetBundle get assetBundle => _assetBundle;

  set assetBundle(AssetBundle value) {
    if (_assetBundle == value) {
      return;
    }
    _assetBundle = value;
    _load();
  }

  Color get color => _color;

  set color(Color value) {
    if (_color == value) {
      return;
    }
    _color = value;
    _paint.colorFilter = ColorFilter.mode(value, BlendMode.srcIn);
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
    if (_image == null) {
      return;
    }
    var canvas = context.canvas;
    canvas.save();
    canvas.drawImageRect(
        _image,
        Rect.fromLTWH(0, 0, _image.width.toDouble(), _image.height.toDouble()),
        offset & size,
        _paint);
    canvas.restore();
  }

  @override
  void performLayout() {
    size = constraints.constrain(_image == null
        ? Size.zero
        : Size(_image.width.toDouble() / _loadedDPR,
            _image.height.toDouble() / _loadedDPR));
  }

  int _loadedDPR = 1;

  Future<void> _load() async {
    if (_assetBundle == null || _filename == null) {
      return;
    }

    String path = '';
    String file = _filename;
    int lastSlash = _filename.lastIndexOf('/');
    if (lastSlash != -1) {
      path = _filename.substring(0, lastSlash);
      file = _filename.substring(lastSlash + 1);
    }

    int closestDPR = ui.window.devicePixelRatio.ceil();
    ByteData data;
    for (int i = closestDPR; i > 1; i--) {
      try {
        data = await _assetBundle.load('$path/$i.0x/$file');
      } catch (_) {
        continue;
      }
      _loadedDPR = i;
      break;
    }

    if (data == null) {
      _loadedDPR = 1;
      data = await _assetBundle.load(_filename);
    }
    if (data == null) {
      return;
    }

    var byteBuffer = Uint8List.view(data.buffer);

    ui.Codec codec = await ui.instantiateImageCodec(byteBuffer);
    ui.FrameInfo frame = await codec.getNextFrame();
    _image = frame.image;
    markNeedsLayout();
  }
}
