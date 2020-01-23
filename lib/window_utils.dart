import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WindowUtils {
  static const MethodChannel _channel = MethodChannel('window_utils');

  static final Random _random = Random.secure();

  static Future<String> openWebView(String key, String url,
      {Offset offset, Size size, String jsMessage = ""}) async {
    return _channel.invokeMethod<String>('openWebView', {
      "key": key,
      "url": url,
      "jsMessage": jsMessage,
      "x": offset?.dx,
      "y": offset?.dy,
      "width": size?.width,
      "height": size?.height,
    });
  }

  static Future<bool> closeWebView(String key) {
    try {
      return _channel.invokeMethod<bool>('closeWebView', {
        "key": key,
      });
    } catch (e) {
      return Future.value(false);
    }
  }

  static Future<bool> resizeWindow(String key, Size size) async {
    return _channel.invokeMethod<bool>('resizeWindow', {
      "key": key,
      "width": size?.width,
      "height": size?.height,
    });
  }

  static Future<bool> moveWindow(String key, Offset offset) async {
    return _channel.invokeMethod<bool>('moveWindow', {
      "key": key,
      "x": offset?.dx,
      "y": offset?.dy,
    });
  }

  static Future<int> keyIndex(String key) {
    return _channel.invokeMethod<int>('keyIndex', {"key": key});
  }

  static Future<int> windowCount() {
    return _channel.invokeMethod<int>('windowCount');
  }

  static Future<String> lastWindowKey() {
    return _channel.invokeMethod<String>("lastWindowKey");
  }

  static Future<Map> getWindowStats(String key) {
    return _channel.invokeMethod<Map>("getWindowStats", {"key": key});
  }

  static Future<Size> getWindowSize(String key) async {
    final _stats = await getWindowStats(key);
    final w = _stats['width'] as double;
    final h = _stats['height'] as double;
    return Size(w, h);
  }

  static Future<Offset> getWindowOffset(String key) async {
    final _stats = await getWindowStats(key);
    final x = _stats['offsetX'] as double;
    final y = _stats['offsetY'] as double;
    return Offset(x, y);
  }

  static String generateKey([int length = 10]) {
    final values = List<int>.generate(length, (i) => _random.nextInt(256));
    return base64Url.encode(values);
  }

  static Future<bool> showTitleBar() {
    return _channel.invokeMethod<bool>('showTitleBar');
  }

  static Future<bool> hideTitleBar() {
    return _channel.invokeMethod<bool>('hideTitleBar');
  }

  static Future<bool> closeWindow() {
    return _channel.invokeMethod<bool>('closeWindow');
  }

  /// [Windows] Only
  static Future<bool> minWindow() {
    return _channel.invokeMethod<bool>('minWindow');
  }

  /// [Windows] Only
  static Future<bool> maxWindow() {
    return _channel.invokeMethod<bool>('maxWindow');
  }

  static Future<bool> centerWindow() {
    return _channel.invokeMethod<bool>('centerWindow');
  }

  static Future<bool> setPosition(Offset offset) {
    return _channel.invokeMethod<bool>('setPosition', {
      'x': offset.dx,
      'y': offset.dy,
    });
  }

  static Future<bool> setSize(Size size) {
    return _channel.invokeMethod<bool>('setSize', {
      'width': size.width,
      'height': size.height,
    });
  }

  static Future<bool> startDrag() {
    return _channel.invokeMethod<bool>('startDrag');
  }

  /// [Windows] Only
  static Future<bool> startResize(DragPosition position) {
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

  static Future<bool> windowTitleDoubleTap() {
    return _channel.invokeMethod<bool>('windowTitleDoubleTap');
  }

  /// [MacOS] Only
  static Future<int> childWindowsCount() {
    return _channel.invokeMethod<int>('childWindowsCount');
  }

  /// Size of Screen that the current window is inside
  static Future<Size> getScreenSize() async {
    final _data =
        await _channel.invokeMethod<Map<String, dynamic>>('getScreenSize');
    return Size(_data['width'] as double, _data['height'] as double);
  }

  static Future<bool> hideCursor() {
    return _channel.invokeMethod<bool>('hideCursor');
  }

  static Future<bool> showCursor() {
    return _channel.invokeMethod<bool>('showCursor');
  }

  static Future<bool> setCursor(CursorType cursor,
      {MacOSCursorType macOS, WindowsCursorType windows}) {
    return _channel.invokeMethod<bool>(
      'setCursor',
      {
        'type': _getCursor(cursor, macOS, windows),
        'update': false,
      },
    );
  }

  static Future<bool> addCursorToStack(CursorType cursor,
      {MacOSCursorType macOS, WindowsCursorType windows}) {
    return _channel.invokeMethod<bool>(
      'setCursor',
      {
        'type': _getCursor(cursor, macOS, windows),
        'update': true,
      },
    );
  }

  static Future<bool> removeCursorFromStack() {
    return _channel.invokeMethod<bool>('removeCursorFromStack');
  }

  static Future<int> mouseStackCount() {
    return _channel.invokeMethod<int>('mouseStackCount');
  }

  static Future<bool> resetCursor() {
    return _channel.invokeMethod<bool>('resetCursor');
  }

  static String _getCursor(
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
    return "none";
  }
}

enum DragPosition {
  top,
  left,
  right,
  bottom,
  topLeft,
  bottomLeft,
  topRight,
  bottomRight
}

enum CursorType {
  arrow,
  cross,
  hand,
  resizeLeft,
  resizeRight,
  resizeDown,
  resizeUp,
  resizeLeftRight,
  resizeUpDown,
}

enum MacOSCursorType {
  arrow,
  beamVertical,
  crossHair,
  closedHand,
  openHand,
  pointingHand,
  resizeLeft,
  resizeRight,
  resizeDown,
  resizeUp,
  resizeLeftRight,
  resizeUpDown,
  beamHorizontial,
  disappearingItem,
  notAllowed,
  dragLink,
  dragCopy,
  contextMenu,
}

enum WindowsCursorType {
  appStart,
  arrow,
  cross,
  hand,
  help,
  iBeam,
  no,
  resizeAll,
  resizeNESW,
  resizeNS,
  resizeNWSE,
  resizeWE,
  upArrow,
  wait,
}
