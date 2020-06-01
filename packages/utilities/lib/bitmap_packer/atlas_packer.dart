import 'dart:math';
import 'dart:typed_data';
import 'package:utilities/bitmap_packer/bitmap_packing_method.dart';
import 'package:utilities/bitmap_packer/bitmap_rect.dart';
import 'package:meta/meta.dart';

@immutable
class _Score {
  final BitmapRect rect;
  final int score1, score2;

  const _Score({
    this.rect,
    this.score1,
    this.score2,
  });
}

/// Find the best location for a set of bitmaps defined by width and height in a
/// larger bitmap.
class AtlasPacker {
  final int maxWidth;
  final int maxHeight;
  final bool allowRotations;

  final List<BitmapRect> _used = [];
  final List<BitmapRect> _free = [];

  int _imageWidth;
  int _imageHeight;
  Uint32List _image;
  Uint32List get image => _image;
  int get imageWidth => _imageWidth;
  int get imageHeight => _imageHeight;

  /// The list of bitmaps that should be placed.
  final List<BitmapRect> _bitmaps = [];
  int get resultLength => _used.length;

  AtlasPacker({
    this.maxWidth,
    this.maxHeight,
    this.allowRotations,
  }) {
    _free.add(BitmapRect(width: maxWidth, height: maxHeight));
  }

  void addBitmap(int width, int height, int padding, Object userData) {
    _bitmaps.add(BitmapRect(
      userData: userData,
      width: width + padding * 2,
      height: height + padding * 2,
      pad: padding,
    ));
  }

  _Score _scoreRect(int width, int height, BitmapPackingMethod method) {
    switch (method) {
      case BitmapPackingMethod.shortSide:
        return _fitShortSide(width, height);
      case BitmapPackingMethod.longSide:
        return _fitLongSide(width, height);
      case BitmapPackingMethod.bestArea:
        return _fitArea(width, height);
      case BitmapPackingMethod.bottomLeft:
        return _fitBottomLeft(width, height);
      case BitmapPackingMethod.contactPoint:
        return _fitContactPoint(width, height);
    }
    return null;
  }

  _Score _fitShortSide(int width, int height) {
    var bestRect = const BitmapRect();
    var score1 = double.maxFinite.toInt();
    var score2 = double.maxFinite.toInt();

    for (final freeRect in _free) {
      if (freeRect.width >= width && freeRect.height >= height) {
        var leftoverHoriz = (freeRect.width - width).abs();
        var leftoverVert = (freeRect.height - height).abs();
        var shortSideFit = min(leftoverHoriz, leftoverVert);
        var longSideFit = max(leftoverHoriz, leftoverVert);

        if (shortSideFit < score1 ||
            (shortSideFit == score1 && longSideFit < score2)) {
          bestRect = freeRect.copyWith(width: width, height: height);
          score1 = shortSideFit;
          score2 = longSideFit;
        }
      }

      if (allowRotations &&
          freeRect.width >= height &&
          freeRect.height >= width) {
        var flippedLeftoverHoriz = (freeRect.width - height).abs();
        var flippedLeftoverVert = (freeRect.height - width).abs();
        var flippedShortSideFit =
            min(flippedLeftoverHoriz, flippedLeftoverVert);
        var flippedLongSideFit = max(flippedLeftoverHoriz, flippedLeftoverVert);

        if (flippedShortSideFit < score1 ||
            (flippedShortSideFit == score1 && flippedLongSideFit < score2)) {
          bestRect =
              freeRect.copyWith(width: height, height: width, rotated: true);
          score1 = flippedShortSideFit;
          score2 = flippedLongSideFit;
        }
      }
    }
    return bestRect.width == 0 || bestRect.height == 0
        ? null
        : _Score(
            rect: bestRect,
            score1: score1,
            score2: score2,
          );
  }

  _Score _fitLongSide(int width, int height) {
    var bestRect = const BitmapRect();
    var score1 = double.maxFinite.toInt();
    var score2 = double.maxFinite.toInt();

    for (final freeRect in _free) {
      // Try to place the rectangle in upright (non-flipped) orientation.
      if (freeRect.width >= width && freeRect.height >= height) {
        var leftoverHoriz = (freeRect.width - width).abs();
        var leftoverVert = (freeRect.height - height).abs();
        var shortSideFit = min(leftoverHoriz, leftoverVert);
        var longSideFit = max(leftoverHoriz, leftoverVert);

        if (longSideFit < score2 ||
            (longSideFit == score2 && shortSideFit < score1)) {
          bestRect = freeRect.copyWith(width: width, height: height);
          score1 = shortSideFit;
          score2 = longSideFit;
        }
      }

      if (allowRotations &&
          freeRect.width >= height &&
          freeRect.height >= width) {
        var leftoverHoriz = (freeRect.width - height).abs();
        var leftoverVert = (freeRect.height - width).abs();
        var shortSideFit = min(leftoverHoriz, leftoverVert);
        var longSideFit = max(leftoverHoriz, leftoverVert);

        if (longSideFit < score2 ||
            (longSideFit == score2 && shortSideFit < score1)) {
          bestRect =
              freeRect.copyWith(width: height, height: width, rotated: true);
          score1 = shortSideFit;
          score2 = longSideFit;
        }
      }
    }
    return bestRect.width == 0 || bestRect.height == 0
        ? null
        : _Score(
            rect: bestRect,
            score1: score1,
            score2: score2,
          );
  }

  _Score _fitArea(int width, int height) {
    var bestRect = const BitmapRect();
    var score1 = double.maxFinite.toInt();
    var score2 = double.maxFinite.toInt();

    for (final freeRect in _free) {
      var areaFit = freeRect.width * freeRect.height - width * height;

      // Try to place the rectangle in upright (non-flipped) orientation.
      if (freeRect.width >= width && freeRect.height >= height) {
        var leftoverHoriz = (freeRect.width - width).abs();
        var leftoverVert = (freeRect.height - height).abs();
        var shortSideFit = min(leftoverHoriz, leftoverVert);

        if (areaFit < score2 || (areaFit == score2 && shortSideFit < score1)) {
          bestRect = freeRect.copyWith(width: width, height: height);
          score1 = shortSideFit;
          score2 = areaFit;
        }
      }

      if (allowRotations &&
          freeRect.width >= height &&
          freeRect.height >= width) {
        var leftoverHoriz = (freeRect.width - height).abs();
        var leftoverVert = (freeRect.height - width).abs();
        var shortSideFit = min(leftoverHoriz, leftoverVert);

        if (areaFit < score2 || (areaFit == score2 && shortSideFit < score1)) {
          bestRect =
              freeRect.copyWith(width: height, height: width, rotated: true);
          score1 = shortSideFit;
          score2 = areaFit;
        }
      }
    }
    return bestRect.width == 0 || bestRect.height == 0
        ? null
        : _Score(
            rect: bestRect,
            score1: score1,
            score2: score2,
          );
  }

  _Score _fitBottomLeft(int width, int height) {
    var bestRect = const BitmapRect();
    var score1 = double.maxFinite.toInt();
    var score2 = double.maxFinite.toInt();

    for (final freeRect in _free) {
      // Try to place the rectangle in upright (non-flipped) orientation.
      if (freeRect.width >= width && freeRect.height >= height) {
        var topSideY = freeRect.y + height;
        if (topSideY < score1 || (topSideY == score1 && freeRect.x < score2)) {
          bestRect = freeRect.copyWith(width: width, height: height);
          score1 = topSideY;
          score2 = freeRect.x;
        }
      }
      if (allowRotations &&
          freeRect.width >= height &&
          freeRect.height >= width) {
        var topSideY = freeRect.y + width;
        if (topSideY < score1 || (topSideY == score1 && freeRect.x < score2)) {
          bestRect = freeRect.copyWith(width: height, height: width);
          score1 = topSideY;
          score2 = freeRect.x;
        }
      }
    }
    return bestRect.width == 0 || bestRect.height == 0
        ? null
        : _Score(
            rect: bestRect,
            score1: score1,
            score2: score2,
          );
  }

  int _contactPointScore(int x, int y, int width, int height) {
    int score = 0;

    if (x == 0 || x + width == maxWidth) {
      score += height;
    }
    if (y == 0 || y + height == maxHeight) {
      score += width;
    }

    for (final usedRect in _used) {
      if (usedRect.x == x + width || usedRect.x + usedRect.width == x) {
        score += _commonIntervalLength(
            usedRect.y, usedRect.y + usedRect.height, y, y + height);
      }
      if (usedRect.y == y + height || usedRect.y + usedRect.height == y) {
        score += _commonIntervalLength(
            usedRect.x, usedRect.x + usedRect.width, x, x + width);
      }
    }
    return score;
  }

  _Score _fitContactPoint(int width, int height) {
    var bestRect = const BitmapRect();
    var score1 = -1;

    for (final freeRect in _free) {
      // Try to place the rectangle in upright (non-flipped) orientation.
      if (freeRect.width >= width && freeRect.height >= height) {
        var score = _contactPointScore(freeRect.x, freeRect.y, width, height);
        if (score > score1) {
          bestRect = freeRect.copyWith(width: width, height: height);
          score1 = score;
        }
      }
      if (allowRotations &&
          freeRect.width >= height &&
          freeRect.height >= width) {
        var score = _contactPointScore(freeRect.x, freeRect.y, height, width);
        if (score > score1) {
          bestRect =
              freeRect.copyWith(width: height, height: width, rotated: true);
          score1 = score;
        }
      }
    }
    return bestRect.width == 0 || bestRect.height == 0
        ? null
        : _Score(
            rect: bestRect,
            // Contact point score is higher when better, so invert it.
            score1: -score1,
            score2: double.maxFinite.toInt(),
          );
  }

  bool _split(BitmapRect freeNode, BitmapRect usedNode) {
    // Test with SAT if the rectangles even intersect.
    if (usedNode.x >= freeNode.x + freeNode.width ||
        usedNode.x + usedNode.width <= freeNode.x ||
        usedNode.y >= freeNode.y + freeNode.height ||
        usedNode.y + usedNode.height <= freeNode.y) {
      return false;
    }

    if (usedNode.x < freeNode.x + freeNode.width &&
        usedNode.x + usedNode.width > freeNode.x) {
      // New node at the top side of the used node.
      if (usedNode.y > freeNode.y &&
          usedNode.y < freeNode.y + freeNode.height) {
        var newNode = freeNode.copyWith(height: usedNode.y - freeNode.y);
        _free.add(newNode);
      }

      // New node at the bottom side of the used node.
      if (usedNode.y + usedNode.height < freeNode.y + freeNode.height) {
        var newNode = freeNode.copyWith(
            y: usedNode.y + usedNode.height,
            height:
                freeNode.y + freeNode.height - (usedNode.y + usedNode.height));
        _free.add(newNode);
      }
    }

    if (usedNode.y < freeNode.y + freeNode.height &&
        usedNode.y + usedNode.height > freeNode.y) {
      // New node at the left side of the used node.
      if (usedNode.x > freeNode.x && usedNode.x < freeNode.x + freeNode.width) {
        var newNode = freeNode.copyWith(width: usedNode.x - freeNode.x);
        _free.add(newNode);
      }

      // New node at the right side of the used node.
      if (usedNode.x + usedNode.width < freeNode.x + freeNode.width) {
        var newNode = freeNode.copyWith(
            x: usedNode.x + usedNode.width,
            width: freeNode.x + freeNode.width - (usedNode.x + usedNode.width));

        _free.add(newNode);
      }
    }

    return true;
  }

  void _prune() {
    for (var i = 0; i < _free.length; i++) {
      for (var j = i + 1; j < _free.length; j++) {
        if (_isContainedIn(_free[i], _free[j])) {
          _free.removeAt(i);
          i--;
          break;
        }
        if (_isContainedIn(_free[j], _free[i])) {
          _free.removeAt(j);
          j--;
        }
      }
    }
  }

  void _place(BitmapRect rect) {
    var numRectanglesToProcess = _free.length;
    for (var i = 0; i < numRectanglesToProcess; ++i) {
      if (_split(_free[i], rect)) {
        _free.removeAt(i);
        i--;
        numRectanglesToProcess--;
      }
    }

    _prune();

    _used.add(rect);
  }

  void pack(BitmapPackingMethod method) {
    
    assert(_used.isEmpty, 'cannot have already run');
    var bitmaps = _bitmaps.toList(growable: true);
    while (bitmaps.isNotEmpty) {
      var bestScore1 = double.maxFinite.toInt();
      var bestScore2 = double.maxFinite.toInt();
      BitmapRect bestPlaceRect;
      int bestPlaceIndex = -1;

      for (var i = 0; i < bitmaps.length; i++) {
        var rect = bitmaps[i];

        var result = _scoreRect(rect.width, rect.height, method);
        if (result != null &&
            (result.score1 < bestScore1 ||
                (result.score1 == bestScore1 && result.score2 < bestScore2))) {
          bestScore1 = result.score1;
          bestScore2 = result.score2;
          bestPlaceIndex = i;
          
          bestPlaceRect = result.rect.copyWith(
            userData: rect.userData,
            pad: rect.pad,
          );
        }
      }

      if (bestPlaceRect == null) {
        break;
      }

      _place(bestPlaceRect);
      bitmaps.removeAt(bestPlaceIndex);
    }
  }

  Iterable<BitmapRect> get results => _used.map((used) => used.copyWith(
        x: used.x + used.pad,
        y: used.y + used.pad,
        width: used.width - used.pad * 2,
        height: used.height - used.pad * 2,
      ));

  void initImage() {
    int imageWidth = 0;
    int imageHeight = 0;
    for (final use in _used) {
      if (use.x + use.width > imageWidth) {
        imageWidth = use.x + use.width;
      }
      if (use.y + use.height > imageHeight) {
        imageHeight = use.y + use.height;
      }

      _image = Uint32List(imageWidth * imageHeight);
      _imageWidth = imageWidth;
      _imageHeight = imageHeight;
    }
  }

  /// Copy pixels into destination image rect.
  void copyPixels(BitmapRect rect, Uint32List sourcePixels) {
    assert(_image != null, 'call initImage before copyPixels');
    // Copy to the destination, padding gets filled with bleed.
    var pad = rect.pad;
    var sourceWidth = rect.width - pad * 2;
    var sourceHeight = rect.height - pad * 2;
    if (rect.rotated) {
      int s = sourceWidth;
      sourceWidth = sourceHeight;
      sourceHeight = s;
    }
    for (int x = 0; x < rect.width; x++) {
      for (int y = 0; y < rect.height; y++) {
        int rx, ry, dx, dy;
        if (rect.rotated) {
          rx = (y - pad).clamp(0, sourceWidth - 1) as int;
          ry = (x - pad).clamp(0, sourceHeight - 1) as int;
          // dx = rect.x + y;
          // dy = rect.y + x;
        } else {
          rx = (x - pad).clamp(0, sourceWidth - 1) as int;
          ry = (y - pad).clamp(0, sourceHeight - 1) as int;
        }
        dx = rect.x + x;
        dy = rect.y + y;

        _image[dy * _imageWidth + dx] = sourcePixels[ry * sourceWidth + rx];
      }
    }
  }
}

/// Returns 0 if the two intervals i1 and i2 are disjoint,
/// or the length of their overlap otherwise.
int _commonIntervalLength(int i1start, int i1end, int i2start, int i2end) {
  if (i1end < i2start || i2end < i1start) {
    return 0;
  }
  return min(i1end, i2end) - max(i1start, i2start) as int;
}

bool _isContainedIn(BitmapRect a, BitmapRect b) =>
    a.x >= b.x &&
    a.y >= b.y &&
    a.x + a.width <= b.x + b.width &&
    a.y + a.height <= b.y + b.height;
