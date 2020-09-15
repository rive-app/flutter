import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/image_cache.dart';
import 'package:rive_editor/rive/managers/image_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/shortcuts/default_key_binding.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_key_binding.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_keys.dart';
import 'package:rive_editor/widgets/theme.dart';

/// Inherited widget that will pass the theme down the tree
/// To access the theme data anywhere in a Flutter context, use:
///
/// RiveTheme.of(context).colors.buttonLight
///
class RiveTheme extends InheritedWidget {
  const RiveTheme({
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  RiveThemeData get theme => RiveThemeData();

  static RiveThemeData of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RiveTheme>().theme;

  static RiveThemeData find(BuildContext context) =>
      context.findAncestorWidgetOfExactType<RiveTheme>().theme;

  @override
  bool updateShouldNotify(RiveTheme old) => theme != old.theme;
}

/// Inherited widget that will pass the theme down the tree
/// To access the theme data anywhere in a Flutter context, use:
///
/// ImageAssetCache.of(context).load('tool-add.png');
///
class ImageAssetCache extends InheritedWidget {
  const ImageAssetCache({
    @required this.cache,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final RiveImageCache cache;

  static RiveImageCache of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ImageAssetCache>().cache;

  @override
  bool updateShouldNotify(ImageAssetCache old) => cache != old.cache;
}

/// Inherited widget that will pass the shortcut key bindings down the tree
/// To access the bindings anywhere in a Flutter context, use:
///
/// ShortcutBindings.of(context)
///
class ShortcutBindings extends InheritedWidget {
  const ShortcutBindings({
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  ShortcutKeyBinding get bindings => defaultKeyBinding;

  static ShortcutKeyBinding of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShortcutBindings>().bindings;

  @override
  bool updateShouldNotify(ShortcutBindings old) => bindings != old.bindings;
}

/// Inherited widget that will pass the rive context? down the tree
/// To access rive anywhere in a Flutter context, use:
///
/// Rive.of(context).colors.buttonLight
///
class RiveContext extends InheritedWidget {
  const RiveContext({
    @required this.rive,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final Rive rive;

  static Rive of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RiveContext>().rive;
  }

  /// Call this when you don't want the context to depend on this (usually you
  /// want this as Rive never changes anyway).
  static Rive find(BuildContext context) {
    return context.findAncestorWidgetOfExactType<RiveContext>().rive;
  }

  @override
  bool updateShouldNotify(RiveContext old) => rive != old.rive;
}

/// Easy way to grab the active file from the context.
class ActiveFile extends InheritedWidget {
  const ActiveFile({
    @required this.file,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final OpenFileContext file;

  static OpenFileContext of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ActiveFile>().file;

  static OpenFileContext find(BuildContext context) =>
      context.findAncestorWidgetOfExactType<ActiveFile>().file;

  @override
  bool updateShouldNotify(ActiveFile old) => file != old.file;
}

// Image manager state provider

class ImageCacheProvider extends StatefulWidget {
  const ImageCacheProvider({@required this.manager, this.child});
  final Widget child;
  final ImageManager manager;

  @override
  _ImageCacheProviderState createState() => _ImageCacheProviderState();

  static ImageManager of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedImageCacheProvider>()
      .manager;
}

class _ImageCacheProviderState extends State<ImageCacheProvider> {
  ImageManager _manager;

  @override
  void initState() {
    _manager = widget.manager;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _InheritedImageCacheProvider(
        manager: _manager,
        child: widget.child,
      );
}

class _InheritedImageCacheProvider extends InheritedWidget {
  const _InheritedImageCacheProvider({
    @required this.manager,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final ImageManager manager;

  @override
  bool updateShouldNotify(_InheritedImageCacheProvider old) =>
      manager != old.manager;
}

typedef KeyPressCallback = void Function(
    ShortcutKey key, bool isPress, bool isRepeat);

class KeyPressProvider extends StatefulWidget {
  const KeyPressProvider({@required this.listener, this.child});
  final Widget child;
  final KeyPressCallback listener;

  @override
  _KeyPressProviderState createState() => _KeyPressProviderState();
}

class _KeyPressProviderState extends State<KeyPressProvider> {
  final eventChannel = const EventChannel('plugins.rive.app/key_press');
  StreamSubscription _subscription;
  @override
  void initState() {
    _subscription = eventChannel.receiveBroadcastStream().listen(_onKeyEvent);
    super.initState();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onKeyEvent(dynamic event) {
    assert(event is int);
    var code = event as int;
    var isRelease = (code & (1 << 18)) != 0;
    var isRepeat = (code & (1 << 17)) != 0;
    var keyCode = code & ~(1 << 18 | 1 << 17);
    // print('KEY: ${keyForCode(keyCode)}');
    // if (isRelease) {
    //   print('Released: $keyCode');
    // } else {
    //   print('Pressed: $keyCode $isRepeat');
    // }
    var key = keyForCode(keyCode);
    if (key != null) {
      widget.listener?.call(key, !isRelease, isRepeat);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
