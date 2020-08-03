import 'src/platform_native.dart'
    if (dart.library.html) 'src/platform_web.dart';

abstract class Platform {
  bool get isMac;
  bool get isTouchDevice;
  bool get isWeb;

  static final Platform instance = makePlatform();
}
