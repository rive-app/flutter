import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:window_utils_platform_interface/window_utils_platform_interface.dart';

export 'package:window_utils_platform_interface/window_utils_platform_interface.dart';

Future<String> openWebView(String key, String url,
        {Offset offset, Size size, String jsMessage = ''}) =>
    WindowUtilsPlatform.instance.openWebView(key, url,
        offset: offset, size: size, jsMessage: jsMessage);

Future<bool> closeWebView(String key) =>
    WindowUtilsPlatform.instance.closeWebView(key);

Future<bool> resizeWindow(String key, Size size) =>
    WindowUtilsPlatform.instance.resizeWindow(key, size);

Future<bool> moveWindow(String key, Offset offset) =>
    WindowUtilsPlatform.instance.moveWindow(key, offset);

Future<int> keyIndex(String key) => WindowUtilsPlatform.instance.keyIndex(key);

Future<int> windowCount() => WindowUtilsPlatform.instance.windowCount();

Future<String> lastWindowKey() => WindowUtilsPlatform.instance.lastWindowKey();

Future<Map> getWindowStats([String key]) =>
    WindowUtilsPlatform.instance.getWindowStats(key);

Future<Size> getWindowSize([String key]) =>
    WindowUtilsPlatform.instance.getWindowSize(key);

Future<Offset> getWindowOffset([String key]) =>
    WindowUtilsPlatform.instance.getWindowOffset(key);

String generateKey([int length = 10]) =>
    WindowUtilsPlatform.instance.generateKey(length);

Future<bool> showTitleBar() => WindowUtilsPlatform.instance.showTitleBar();

Future<bool> hideTitleBar() => WindowUtilsPlatform.instance.hideTitleBar();

Future<bool> closeWindow() => WindowUtilsPlatform.instance.closeWindow();

/// [Windows] Only
Future<bool> minWindow() => WindowUtilsPlatform.instance.minWindow();

/// [Windows] Only
Future<bool> maxWindow() => WindowUtilsPlatform.instance.maxWindow();

Future<bool> centerWindow() => WindowUtilsPlatform.instance.centerWindow();

Future<bool> setPosition(Offset offset) =>
    WindowUtilsPlatform.instance.setPosition(offset);

Future<bool> setSize(Size size) => WindowUtilsPlatform.instance.setSize(size);

Future<bool> startDrag() => WindowUtilsPlatform.instance.startDrag();

/// [Windows] Only
Future<bool> startResize(DragPosition position) =>
    WindowUtilsPlatform.instance.startResize(position);

Future<bool> windowTitleDoubleTap() =>
    WindowUtilsPlatform.instance.windowTitleDoubleTap();

/// [MacOS] Only
Future<int> childWindowsCount() =>
    WindowUtilsPlatform.instance.childWindowsCount();

/// Size of Screen that the current window is inside
Future<Size> getScreenSize() => WindowUtilsPlatform.instance.getScreenSize();

Future<bool> hideCursor() => WindowUtilsPlatform.instance.hideCursor();

Future<bool> showCursor() => WindowUtilsPlatform.instance.showCursor();

Future<bool> setCursor(CursorType cursor,
        {MacOSCursorType macOS, WindowsCursorType windows}) =>
    WindowUtilsPlatform.instance
        .setCursor(cursor, macOS: macOS, windows: windows);

Future<bool> addCursorToStack(CursorType cursor,
        {MacOSCursorType macOS, WindowsCursorType windows}) =>
    WindowUtilsPlatform.instance
        .addCursorToStack(cursor, macOS: macOS, windows: windows);

Future<bool> removeCursorFromStack() =>
    WindowUtilsPlatform.instance.removeCursorFromStack();

Future<int> mouseStackCount() => WindowUtilsPlatform.instance.mouseStackCount();

Future<bool> resetCursor() => WindowUtilsPlatform.instance.resetCursor();

Future<Map<String, String>> getCookies() =>
    WindowUtilsPlatform.instance.getCookies();

Future<bool> initDropTarget() => WindowUtilsPlatform.instance.initDropTarget();

/// Start listening to file drops on the main window.
void listenFilesDropped(DroppedFilesCallback callback) {
  WindowUtilsPlatform.filesDropped = callback;
}

/// Stop listening to file drops on the main window.
void cancelFilesDropped(DroppedFilesCallback callback) {
  if (WindowUtilsPlatform.filesDropped == callback) {
    WindowUtilsPlatform.filesDropped = null;
  }
}
