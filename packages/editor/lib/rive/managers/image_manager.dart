import 'dart:typed_data';

/// A test manager for (pre)loading, etc. images
import 'package:http/http.dart' as http;
import 'package:rxdart/subjects.dart';

class ImageManager {
  final _imageCache = <String, Uint8List>{};

  final _firstImage = BehaviorSubject<Uint8List>();
  Stream<Uint8List> get firstImageStream => _firstImage.stream;

  Future<void> loadImage(String url) async {
    // Loads an image into memory from a url
    print('BOB: STARTING IMAGE DL');
    final res = await http.get(url);
    print('BOB: COMPLETED IMAGE DL');
    final bytes = res.bodyBytes;
    print('BOB: STATUS CODE: ${res.statusCode}');
    print('BOB: Loaded ${bytes.length} image bytes');
    _imageCache[url] = bytes;
    _firstImage.add(bytes);
  }
}
