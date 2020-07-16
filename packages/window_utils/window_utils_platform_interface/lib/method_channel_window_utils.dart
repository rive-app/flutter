// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'window_utils_platform_interface.dart';

// const MethodChannel _channel = MethodChannel('plugins.flutter.io/url_launcher');
const MethodChannel _channel = MethodChannel('plugins.rive.app/window_utils');
const EventChannel _keyPressChannel =
    EventChannel('plugins.rive.app/key_press');
final _random = Random.secure();

/// An implementation of [WindowUtilsPlatform] that uses method channels.
class MethodChannelWindowUtils extends WindowUtilsPlatform {
  MethodChannelWindowUtils() {
    _channel.setMethodCallHandler(_channelCallHandler);
  }

  Future<dynamic> _channelCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'filesDropped':
        assert(
            call.arguments is List<dynamic> &&
                (call.arguments as List<dynamic>).cast<String>() != null,
            'expects the plugin to callback with a list of filenames');
        List<DroppedFile> droppedFiles = [];

        for (final filename
            in (call.arguments as List<dynamic>).cast<String>()) {
          var finalSlash = filename.lastIndexOf('/');
          droppedFiles.add(
            DroppedFile(
              finalSlash == -1 ? filename : filename.substring(finalSlash + 1),
              File(filename).readAsBytesSync(),
            ),
          );
        }
        if (droppedFiles.isNotEmpty) {
          WindowUtilsPlatform.filesDropped?.call(droppedFiles);
        }
        return true;
      default:
        return false;
    }
  }

  Future<String> openWebView(String key, String url,
      {Offset offset, Size size, String jsMessage = ''}) async {
    return _channel.invokeMethod<String>('openWebView', {
      'key': key,
      'url': url,
      'jsMessage': jsMessage,
      'x': offset?.dx,
      'y': offset?.dy,
      'width': size?.width,
      'height': size?.height,
    });
  }

  @override
  Future<bool> closeWebView(String key) {
    try {
      return _channel.invokeMethod<bool>('closeWebView', {
        'key': key,
      });
    } catch (e) {
      return Future.value(false);
    }
  }

  @override
  Future<bool> resizeWindow(String key, Size size) async {
    return _channel.invokeMethod<bool>('resizeWindow', {
      'key': key,
      'width': size?.width,
      'height': size?.height,
    });
  }

  @override
  Future<bool> moveWindow(String key, Offset offset) async {
    return _channel.invokeMethod<bool>('moveWindow', {
      'key': key,
      'x': offset?.dx,
      'y': offset?.dy,
    });
  }

  @override
  Future<int> keyIndex(String key) {
    return _channel.invokeMethod<int>('keyIndex', {'key': key});
  }

  @override
  Future<int> windowCount() {
    return _channel.invokeMethod<int>('windowCount');
  }

  @override
  Future<String> lastWindowKey() {
    return _channel.invokeMethod<String>('lastWindowKey');
  }

  @override
  Future<Map> getWindowStats([String key]) {
    return _channel.invokeMethod<Map>('getWindowStats', {'key': key});
  }

  @override
  Future<Size> getWindowSize([String key]) async {
    final _stats = await getWindowStats(key);
    final w = _stats['width'] as double;
    final h = _stats['height'] as double;
    return Size(w, h);
  }

  @override
  Future<Offset> getWindowOffset([String key]) async {
    final _stats = await getWindowStats(key);
    final x = _stats['offsetX'] as double;
    final y = _stats['offsetY'] as double;
    return Offset(x, y);
  }

  @override
  String generateKey([int length = 10]) {
    final values = List<int>.generate(length, (i) => _random.nextInt(256));
    return base64Url.encode(values);
  }

  @override
  Future<bool> showTitleBar() {
    return _channel.invokeMethod<bool>('showTitleBar');
  }

  @override
  Future<bool> hideTitleBar() {
    return _channel.invokeMethod<bool>('hideTitleBar');
  }

  @override
  Future<bool> closeWindow() {
    return _channel.invokeMethod<bool>('closeWindow');
  }

  /// [Windows] Only
  @override
  Future<bool> minWindow() {
    return _channel.invokeMethod<bool>('minWindow');
  }

  /// [Windows] Only
  @override
  Future<bool> maxWindow() {
    return _channel.invokeMethod<bool>('maxWindow');
  }

  @override
  Future<bool> centerWindow() {
    return _channel.invokeMethod<bool>('centerWindow');
  }

  @override
  Future<bool> setPosition(Offset offset) {
    return _channel.invokeMethod<bool>('setPosition', {
      'x': offset.dx,
      'y': offset.dy,
    });
  }

  @override
  Future<bool> setSize(Size size) {
    return _channel.invokeMethod<bool>('setSize', {
      'width': size.width,
      'height': size.height,
    });
  }

  @override
  Future<bool> startDrag() {
    return _channel.invokeMethod<bool>('startDrag');
  }

  /// [Windows] Only
  @override
  Future<bool> startResize(DragPosition position) {
    return _channel.invokeMethod<bool>(
      'startResize',
      {
        'top': position == DragPosition.top ||
            position == DragPosition.topLeft ||
            position == DragPosition.topRight,
        'bottom': position == DragPosition.bottom ||
            position == DragPosition.bottomLeft ||
            position == DragPosition.bottomRight,
        'right': position == DragPosition.right ||
            position == DragPosition.topRight ||
            position == DragPosition.bottomRight,
        'left': position == DragPosition.left ||
            position == DragPosition.topLeft ||
            position == DragPosition.bottomLeft,
      },
    );
  }

  @override
  Future<bool> windowTitleDoubleTap() {
    return _channel.invokeMethod<bool>('windowTitleDoubleTap');
  }

  /// [MacOS] Only
  @override
  Future<int> childWindowsCount() {
    return _channel.invokeMethod<int>('childWindowsCount');
  }

  /// Size of Screen that the current window is inside
  @override
  Future<Size> getScreenSize() async {
    final _data =
        await _channel.invokeMethod<Map<String, dynamic>>('getScreenSize');
    return Size(_data['width'] as double, _data['height'] as double);
  }

  @override
  Future<bool> hideCursor() {
    return _channel.invokeMethod<bool>('hideCursor');
  }

  @override
  Future<bool> showCursor() {
    return _channel.invokeMethod<bool>('showCursor');
  }

  @override
  Future<bool> setCursor(CursorType cursor,
      {MacOSCursorType macOS, WindowsCursorType windows}) {
    return _channel.invokeMethod<bool>(
      'setCursor',
      {
        'type': _getCursor(cursor, macOS, windows),
        'update': false,
      },
    );
  }

  @override
  Future<bool> addCursorToStack(CursorType cursor,
      {MacOSCursorType macOS, WindowsCursorType windows}) {
    return _channel.invokeMethod<bool>(
      'setCursor',
      {
        'type': _getCursor(cursor, macOS, windows),
        'update': true,
      },
    );
  }

  @override
  Future<bool> removeCursorFromStack() {
    return _channel.invokeMethod<bool>('removeCursorFromStack');
  }

  @override
  Future<int> mouseStackCount() {
    return _channel.invokeMethod<int>('mouseStackCount');
  }

  @override
  Future<bool> resetCursor() {
    return _channel.invokeMethod<bool>('resetCursor');
  }

  String _getCursor(
      CursorType cursor, MacOSCursorType macOS, WindowsCursorType windows) {
    if (Platform.isMacOS) {
      if (macOS == null) {
        switch (cursor) {
          case CursorType.arrow:
            macOS = MacOSCursorType.arrow;
            break;
          case CursorType.cross:
            macOS = MacOSCursorType.crossHair;
            break;
          case CursorType.hand:
            macOS = MacOSCursorType.openHand;
            break;
          case CursorType.resizeLeft:
            macOS = MacOSCursorType.resizeLeft;
            break;
          case CursorType.resizeRight:
            macOS = MacOSCursorType.resizeRight;
            break;
          case CursorType.resizeDown:
            macOS = MacOSCursorType.resizeDown;
            break;
          case CursorType.resizeUp:
            macOS = MacOSCursorType.resizeUp;
            break;
          case CursorType.resizeLeftRight:
            macOS = MacOSCursorType.resizeLeftRight;
            break;
          case CursorType.resizeUpDown:
            macOS = MacOSCursorType.resizeUpDown;
            break;
        }
      }
      return describeEnum(macOS);
    }
    if (Platform.isWindows) {
      if (windows == null) {
        switch (cursor) {
          case CursorType.arrow:
            windows = WindowsCursorType.arrow;
            break;
          case CursorType.cross:
            windows = WindowsCursorType.cross;
            break;
          case CursorType.hand:
            windows = WindowsCursorType.hand;
            break;
          case CursorType.resizeLeftRight:
          case CursorType.resizeLeft:
          case CursorType.resizeRight:
            windows = WindowsCursorType.resizeWE;
            break;
          case CursorType.resizeUpDown:
          case CursorType.resizeDown:
          case CursorType.resizeUp:
            windows = WindowsCursorType.resizeNS;
            break;
        }
      }
      return describeEnum(windows);
    }
    return 'none';
  }

  @override
  Future<String> getErrorMessage() async => '';

  @override
  Future<bool> initInputHelper() =>
      _channel.invokeMethod<bool>('initInputHelper');
}
