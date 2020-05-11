import 'dart:typed_data';

import 'package:flutter/material.dart';

/// An experimental manager for caching images
import 'package:http/http.dart' as http;
import 'package:rive_editor/widgets/inherited_widgets.dart';

class ImageManager {
  final _rawImageCache = <String, CachedRawImage>{};

  /// Removes expired entries in the cache
  void _expireCaches() {
    _rawImageCache.removeWhere((key, value) => value.expired);
  }

  Uint8List getCachedImage(String url) {
    if (_rawImageCache.containsKey(url)) {
      return _rawImageCache[url].rawImage;
    }
    return null;
  }

  /// Loads an image into memory from a url
  Future<Uint8List> loadRawImageFromUrl(String url) async {
    _expireCaches();
    if (_rawImageCache.containsKey(url)) {
      return _rawImageCache[url].rawImage;
    }
    final res = await http.get(url);
    final bytes = res.bodyBytes;
    _rawImageCache[url] = CachedRawImage(bytes, DateTime.now());
    return bytes;
  }
}

class CachedCircleAvatar extends StatelessWidget {
  final String imageUrl;

  const CachedCircleAvatar(
    this.imageUrl, {
    Key key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    Uint8List cachedImage =
        ImageCacheProvider.of(context).getCachedImage(imageUrl);

    Widget getAvatar(Uint8List imageData) {
      return CircleAvatar(
        backgroundColor: Colors.transparent,
        backgroundImage: (imageData != null) ? MemoryImage(imageData) : null,
      );
    }

    Widget getCachedAvatar(Uint8List cachedImage) {
      if (cachedImage != null) {
        return getAvatar(cachedImage);
      } else {
        return FutureBuilder<Uint8List>(
            future:
                ImageCacheProvider.of(context).loadRawImageFromUrl(imageUrl),
            builder: (context, snapshot) {
              return getAvatar(snapshot.hasData ? snapshot.data : null);
            });
      }
    }

    return getCachedAvatar(cachedImage);
  }
}

/// Cache ttl (1 hour)
const ttl = Duration(hours: 1);

/// Cached raw image with a timestamp
class CachedRawImage {
  const CachedRawImage(this.rawImage, this.timestamp);
  final Uint8List rawImage;
  final DateTime timestamp;

  bool get expired => timestamp.isAfter(timestamp.add(ttl));
}
