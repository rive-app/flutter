import 'src/platform_native.dart'
    if (dart.library.html) 'src/platform_web.dart';

abstract class Platform {
  bool get isMac;
  bool get isTouchDevice;
  bool get isWeb;
  Map<String, String> get environment;

  static final Platform instance = makePlatform();
}
