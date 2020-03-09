import 'src/platform_stub.dart'
    // ignore: uri_does_not_exist
    if (dart.library.io) 'src/platform_native.dart'
    // ignore: uri_does_not_exist
    if (dart.library.html) 'src/platform_web.dart';

abstract class Platform {
  bool get isMac;

  static final Platform instance = makePlatform();
}
