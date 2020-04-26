import 'dart:typed_data';

/// An experimental manager for caching images
import 'package:http/http.dart' as http;

class ImageManager {
  final _rawImageCache = <String, CachedRawImage>{};

  /// Removes expired entries in the cache
  void _expireCaches() {
    _rawImageCache.removeWhere((key, value) => value.expired);
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

/// Cache ttl (1 hour)
const ttl = Duration(hours: 1);

/// Cached raw image with a timestamp
class CachedRawImage {
  const CachedRawImage(this.rawImage, this.timestamp);
  final Uint8List rawImage;
  final DateTime timestamp;

  bool get expired => timestamp.isAfter(timestamp.add(ttl));
}
