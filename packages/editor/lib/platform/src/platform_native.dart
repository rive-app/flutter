import 'dart:io' as io;

import '../platform.dart';

Platform makePlatform() => PlatformNative();

class PlatformNative extends Platform {
  @override
  bool get isMac => io.Platform.isMacOS;
}
