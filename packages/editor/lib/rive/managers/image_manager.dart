import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// An experimental manager for caching images
import 'package:http/http.dart' as http;
import 'package:rive_editor/widgets/inherited_widgets.dart';

class ImageManager {
  final _rawImageCache = <String, _CachedRawImage>{};

  /// Removes expired entries in the cache
  void _expireCaches() =>
      _rawImageCache.removeWhere((key, value) => value.expired);

  Uint8List getCachedImage(String url) => _rawImageCache[url]?.rawImage;

  /// Loads an image into memory from a url
  Future<Uint8List> loadRawImageFromUrl(String url) async {
    _expireCaches();
    if (_rawImageCache.containsKey(url)) {
      return _rawImageCache[url].completer.future;
    }
    // To make sure we don't double load, immediately store the _CachedRawImage
    // so further calls can get the completer's future (conditional above).
    var cachedImage = _CachedRawImage();
    _rawImageCache[url] = cachedImage;

    // Ok now that we've saved the cache object, start loading...
    final res = await http.get(url);
    final bytes = res.bodyBytes;
    cachedImage.rawImage = bytes;
    
    // Tell anyone waiting for this that it's ready.
    cachedImage.completer.complete(bytes);

    return bytes;
  }
}

class CachedCircleAvatar extends StatelessWidget {
  final String imageUrl;
  final double diameter;
  final VoidCallback onImageError;

  const CachedCircleAvatar(
    this.imageUrl, {
    Key key,
    this.diameter,
    this.onImageError,
  }) : super(key: key);

  Widget _buildAvatar(Uint8List imageData) {
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      maxRadius: diameter != null ? diameter / 2 : null,
      backgroundImage: (imageData != null) ? MemoryImage(imageData) : null,
      onBackgroundImageError: (dynamic _, __) {
        SchedulerBinding.instance
            .addPostFrameCallback((_) => onImageError?.call());
      },
    );
  }

  Future<Widget> _loadAvatar(ImageManager manager) async {
    var bytes = await manager.loadRawImageFromUrl(imageUrl);
    return _buildAvatar(bytes);
  }

  @override
  Widget build(BuildContext context) {
    var imageManager = ImageCacheProvider.find(context);
    final cachedImage = imageManager.getCachedImage(imageUrl);

    return FutureBuilder<Widget>(
      future: cachedImage == null ? _loadAvatar(imageManager) : null,
      builder: (context, snapshot) {
        return snapshot.hasData
            ? snapshot.data
            : const CircularProgressIndicator();
      },
      initialData: cachedImage != null
          ? _buildAvatar(cachedImage)
          : const CircularProgressIndicator(),
    );
  }
}

/// Cache ttl (1 hour)
const ttl = Duration(hours: 1);

/// Cached raw image with a timestamp
class _CachedRawImage {
  Uint8List rawImage;
  final DateTime timestamp = DateTime.now();
  final Completer<Uint8List> completer = Completer<Uint8List>();

  bool get expired => timestamp.isAfter(timestamp.add(ttl));
}
