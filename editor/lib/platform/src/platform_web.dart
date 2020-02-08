import 'dart:html' as html;

import '../platform.dart';

Platform makePlatform() => PlatformWeb();

class PlatformWeb extends Platform {
  @override
  bool get isMac => html.window.navigator.appVersion.contains('Mac');
}
