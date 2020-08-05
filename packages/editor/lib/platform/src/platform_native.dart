import 'dart:io' as io show Platform;

import '../platform.dart';

Platform makePlatform() => PlatformNative();

class PlatformNative extends Platform {
  @override
  bool get isWeb => false;

  @override
  bool get isMac => io.Platform.isMacOS;

  @override
  bool get isTouchDevice => io.Platform.isAndroid || io.Platform.isIOS;
}
