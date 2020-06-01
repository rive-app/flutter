import 'package:meta/meta.dart';

@immutable
class BitmapRect {
  final int x, y, width, height, pad;
  final Object userData;
  final bool rotated;

  const BitmapRect({
    this.x = 0,
    this.y = 0,
    this.width = 0,
    this.height = 0,
    this.pad = 0,
    this.rotated = false,
    this.userData,
  });

  BitmapRect copyWith({
    int x,
    int y,
    int width,
    int height,
    int pad,
    Object userData,
    bool rotated,
  }) {
    return BitmapRect(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      pad: pad ?? this.pad,
      userData: userData ?? this.userData,
      rotated: rotated ?? this.rotated,
    );
  }
}
