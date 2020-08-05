import 'dart:html' as html;

import '../platform.dart';

Platform makePlatform() => PlatformWeb();

class PlatformWeb extends Platform {
  @override
  bool get isMac => html.window.navigator.appVersion.contains('Mac');

  @override
  bool get isWeb => true;

  @override
  bool get isTouchDevice =>
      html.window.navigator.userAgent.contains('Android') ||
      html.window.navigator.userAgent.contains('iPhone');
}
