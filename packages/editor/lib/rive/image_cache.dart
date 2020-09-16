import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// An image stored in the cache and a completer to await its loading.
class CachedImage {
  final Completer<CachedImage> completer = Completer<CachedImage>();
  ui.Image image;
}

/// The cache holder which should be stored somewhere long lived for the
/// duration of the app.
class RiveImageCache {
  final Map<String, CachedImage> _cache = {};
  final AssetBundle assetBundle;

  RiveImageCache(this.assetBundle);

  Future<CachedImage> load(String filename) async {
    if (filename == null) {
      return null;
    }
    assert(!_cache.keys.contains(filename));
    var cachedImage = CachedImage();
    _cache[filename] = cachedImage;

    ByteData data = await assetBundle.load(filename);

    if (data == null) {
      throw FormatException('Unable to load icon asset $filename');
    }

    var byteBuffer = Uint8List.view(data.buffer);
    ui.decodeImageFromList(byteBuffer, (image) {
      cachedImage.image = image;
      cachedImage.completer.complete(cachedImage);
    });

    return cachedImage.completer.future;
  }

  CachedImage image(String filename) => _cache[filename];
}

class DpiImage {
  CachedImage result;
  double devicePixelRatio;
  final void Function() loaded;
  final String Function(double dpi) filenameFor;
  final RiveImageCache cache;

  ui.Image get image {
    var dpr = ui.window.devicePixelRatio;
    if (ui.window.devicePixelRatio == devicePixelRatio) {
      return result?.image;
    }
    devicePixelRatio = dpr;
    String filename = filenameFor(ui.window.devicePixelRatio);
    result = cache.image(filename);
    if (result != null) {
      result.completer.future.then((image) {
        loaded();
      });
      return result.image;
    } else {
      cache.load(filename).then((cachedImage) {
        result = cachedImage;
        loaded();
      });
      return null;
    }
  }

  DpiImage({
    @required this.loaded,
    @required this.cache,
    @required this.filenameFor,
  });
}
