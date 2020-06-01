import 'package:utilities/bitmap_packer/atlas_packer.dart';
import 'package:utilities/bitmap_packer/bitmap_packing_method.dart';
import 'package:utilities/bitmap_packer/bitmap_rect.dart';

class MultiAtlasPacker {
  final int maxWidth;
  final int maxHeight;
  final bool allowRotations;

  /// The list of bitmaps that should be placed.
  final List<BitmapRect> _bitmaps = [];

  MultiAtlasPacker({this.maxWidth, this.maxHeight, this.allowRotations});

  void addBitmap(int width, int height, int padding, Object userData) {
    _bitmaps.add(BitmapRect(
      userData: userData,
      width: width,
      height: height,
      pad: padding,
    ));
  }

  Iterable<AtlasPacker> build() {
    // Insert large images first.
    _bitmaps.sort((a, b) => a.width * a.height - b.width * b.height);
    return _pack(_bitmaps);
  }

  Iterable<AtlasPacker> _pack(Iterable<BitmapRect> bitmaps,
      [List<AtlasPacker> results]) {
    results ??= List<AtlasPacker>();

    AtlasPacker best;
    for (final method in BitmapPackingMethod.values) {
      var packer = AtlasPacker(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          allowRotations: allowRotations);
      for (final bitmap in bitmaps) {
        packer.addBitmap(bitmap.width, bitmap.height, bitmap.pad, bitmap);
      }
      packer.pack(method);

      // Pick whichever packed the most.
      if (best == null || packer.resultLength > best.resultLength) {
        best = packer;
      }
    }

    if (best != null && best.resultLength > 0) {
      results.add(best);
    }
    if (best != null &&
        best.resultLength != 0 &&
        best.resultLength != bitmaps.length) {
      // Find what didn't get packed and keep packing it.
      var packedResults = best.results;
      var leftOver = bitmaps.toSet();
      for (final result in packedResults) {
        leftOver.remove(result.userData as BitmapRect);
      }
      _pack(leftOver, results);
    }
    return results;
  }
}
