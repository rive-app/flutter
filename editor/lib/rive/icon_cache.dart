import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

/// An image stored in the cache with the resolution that was selected at load
/// time to best fit the screen the app is currently running on.
class CachedImage {
  final Completer<CachedImage> completer = Completer<CachedImage>();
  int resolution;
  ui.Image image;
}

/// The cache holder which should be stored somewhere long lived for the
/// duration of the app.
class RiveIconCache {
  final Map<String, CachedImage> _cache = {};
  final AssetBundle assetBundle;

  RiveIconCache(this.assetBundle);

  Future<CachedImage> load(String filename) async {
    if (filename == null) {
      return null;
    }
    assert(!_cache.keys.contains(filename));
    var cachedImage = CachedImage();
    _cache[filename] = cachedImage;

    String path = '';
    String file = filename;
    int lastSlash = filename.lastIndexOf('/');
    if (lastSlash != -1) {
      path = filename.substring(0, lastSlash);
      file = filename.substring(lastSlash + 1);
    }

    int desiredResolution = ui.window.devicePixelRatio.ceil();
    int foundResolution;
    ByteData data;
    for (int i = desiredResolution; i > 1; i--) {
      try {
        data = await assetBundle.load('$path/$i.0x/$file');
      } catch (_) {
        continue;
      }
      foundResolution = i;
      break;
    }

    if (data == null) {
      foundResolution = 1;
      data = await assetBundle.load(filename);
    }
    if (data == null) {
      return null;
    }

    var byteBuffer = Uint8List.view(data.buffer);

    ui.Codec codec = await ui.instantiateImageCodec(byteBuffer);
    ui.FrameInfo frame = await codec.getNextFrame();
    cachedImage.resolution = foundResolution;
    cachedImage.image = frame.image;
    cachedImage.completer.complete(cachedImage);
    return cachedImage;
  }

  CachedImage image(String filename) => _cache[filename];
}
