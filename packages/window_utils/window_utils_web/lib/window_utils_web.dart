import 'dart:async';
import 'dart:html' as html;
import 'dart:ui';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:window_utils_platform_interface/window_utils_platform_interface.dart';
import 'package:window_utils_web/browser.dart' as browser;

/// The web implementation of [WindowUtilsPlatform].
///
/// This class implements (or stubs out) `package:window_utils` functionality for the web.
class WindowUtilsPlugin extends WindowUtilsPlatform {
  /// Registers this class as the default instance of [UrlLauncherPlatform].
  static void registerWith(Registrar registrar) {
    WindowUtilsPlatform.instance = WindowUtilsPlugin();
  }

  /// Stubbed out for web; does nothing except return true
  @override
  Future<bool> hideTitleBar() => Future.value(true);

  /// Stubbed out for web; does nothing except return true
  @override
  Future<bool> setSize(Size size) => Future.value(true);

  /// Stubbed out for web; does nothing except return true
  @override
  Future<bool> startDrag() => Future.value(true);

  /// Stubbed out for web; does nothing except return the zero offset
  @override
  Future<Offset> getWindowOffset([String key]) => Future.value(Offset.zero);

  /// Stubbed out for web; does nothing except return the zero offset
  @override
  Future<Size> getWindowSize([String key]) => Future.value(Size(
        browser.width.toDouble(),
        browser.height.toDouble(),
      ));

  /// On web: just navigate to [url] and return an empty String.
  @override
  Future<String> openWebView(
    String key,
    String url, {
    Offset offset,
    Size size,
    String jsMessage = '',
  }) {
    /**See https://github.com/flutter/flutter/issues/51461 for reference.
    final target = browser.standalone ? '_top' : '';
    html.window.open(url, target); 
    */
    html.window.location.href = url;
    return Future.value('');
  }

  /// Stubbed out for web; does nothing except return true
  @override
  Future<bool> closeWebView(String key) => Future.value(true);

  @override
  Future<String> getErrorMessage() async {
    var cookieString = html.window.document.cookie;
    final cookies = <String, String>{};
    var allCookies = cookieString.split('; ');

    for (final cookie in allCookies) {
      var kvCookie = cookie.split('=');
      if (kvCookie.length != 2) {
        continue;
      }

      var k = kvCookie[0];
      var v = kvCookie[1];
      cookies[k] = v;
    }

    var res = cookies['errorMsg'];
    if (res != null) {
      // Clean up error before returning.
      res = Uri.decodeComponent(res);
    }
    return res;
  }
}
