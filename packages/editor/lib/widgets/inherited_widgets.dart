import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/artboard.dart';
import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/managers/animation/animations_manager.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/rive/managers/animation/keyframe_manager.dart';
import 'package:rive_editor/rive/managers/follow_manager.dart';
import 'package:rive_editor/rive/managers/image_manager.dart';
import 'package:rive_editor/rive/open_file_context.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/rive/shortcuts/default_key_binding.dart';
import 'package:rive_editor/rive/shortcuts/shortcut_key_binding.dart';
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
/// IconCache.of(context).load('tool-add');
///
class IconCache extends InheritedWidget {
  const IconCache({
    @required this.cache,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final RiveIconCache cache;

  static RiveIconCache of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<IconCache>().cache;

  @override
  bool updateShouldNotify(IconCache old) => cache != old.cache;
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

// Follow state provider

class FollowProvider extends StatefulWidget {
  const FollowProvider({@required this.manager, this.child});
  final Widget child;
  final FollowManager manager;

  @override
  _FollowProviderState createState() => _FollowProviderState();

  static FollowManager of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedFollowProvider>()
      .manager;
}

class _FollowProviderState extends State<FollowProvider> {
  FollowManager _manager;

  @override
  void initState() {
    _manager = widget.manager;
    super.initState();
  }

  @override
  Widget build(BuildContext context) => _InheritedFollowProvider(
        manager: _manager,
        child: widget.child,
      );
}

class _InheritedFollowProvider extends InheritedWidget {
  const _InheritedFollowProvider({
    @required this.manager,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final FollowManager manager;

  @override
  bool updateShouldNotify(_InheritedFollowProvider old) =>
      manager != old.manager;
}

// Animation provider. This is responsible for building new managers when active
// artboard changes.
class AnimationsProvider extends StatefulWidget {
  const AnimationsProvider({@required this.activeArtboard, this.child});
  final Widget child;
  final Artboard activeArtboard;

  @override
  _AnimationsProviderState createState() => _AnimationsProviderState();

  static AnimationsManager of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedAnimationProvider>()
      ?.manager;
}

class _AnimationsProviderState extends State<AnimationsProvider> {
  AnimationsManager _manager;

  @override
  void initState() {
    _updateManager(widget.activeArtboard);
    super.initState();
  }

  void _updateManager(Artboard activeArtboard) {
    // If the Core context changes, disable animation on it.
    if (_manager?.activeArtboard?.context != activeArtboard?.context) {
      _manager?.activeArtboard?.context?.stopAnimating();
    }
    _manager?.dispose();
    _manager = activeArtboard == null
        ? null
        : AnimationsManager(activeArtboard: activeArtboard);
    _manager?.activeArtboard?.context?.startAnimating();
  }

  @override
  void didUpdateWidget(AnimationsProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeArtboard != widget.activeArtboard) {
      _updateManager(widget.activeArtboard);
    }
  }

  @override
  void dispose() {
    // We're a goner, get rid of the manager and clean up animation mode.
    _updateManager(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _InheritedAnimationProvider(
        manager: _manager,
        child: widget.child,
      );
}

class _InheritedAnimationProvider extends InheritedWidget {
  const _InheritedAnimationProvider({
    @required this.manager,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final AnimationsManager manager;

  @override
  bool updateShouldNotify(_InheritedAnimationProvider old) =>
      manager != old.manager;
}

// Linear Animation provider. This is responsible for building new managers when
// the editing animation changes.
class EditingAnimationProvider extends StatelessWidget {
  final Widget child;

  const EditingAnimationProvider({Key key, this.child}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    var stream = AnimationsProvider.of(context)?.selectedAnimation;
    return stream == null
        ? SizedBox(child: child)
        : StreamBuilder<AnimationViewModel>(
            stream: AnimationsProvider.of(context)?.selectedAnimation,
            builder: (context, snapshot) => _EditingAnimation(
              child: child,
              activeFile: ActiveFile.of(context),
              editingAnimation:
                  snapshot.hasData && snapshot.data.animation is LinearAnimation
                      ? snapshot.data.animation as LinearAnimation
                      : null,
            ),
          );
  }

  static EditingAnimationManager of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedEditingAnimation>()
      ?.editingAnimationManager;

  static EditingAnimationManager find(BuildContext context) => context
      .findAncestorWidgetOfExactType<_InheritedEditingAnimation>()
      ?.editingAnimationManager;
}

class KeyFrameManagerProvider {
  static KeyFrameManager of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedKeyFrameManager>()
      ?.keyFrameManager;

  static KeyFrameManager find(BuildContext context) => context
      .findAncestorWidgetOfExactType<_InheritedKeyFrameManager>()
      ?.keyFrameManager;
}

class _EditingAnimation extends StatefulWidget {
  final LinearAnimation editingAnimation;
  final OpenFileContext activeFile;
  final Widget child;
  const _EditingAnimation({
    @required this.editingAnimation,
    @required this.activeFile,
    @required this.child,
    Key key,
  }) : super(key: key);

  @override
  __EditingAnimationState createState() => __EditingAnimationState();
}

class __EditingAnimationState extends State<_EditingAnimation> {
  EditingAnimationManager _manager;
  KeyFrameManager _keyFrameManager;

  @override
  void initState() {
    super.initState();
    _updateManager();
  }

  @override
  void dispose() {
    super.dispose();
    _manager?.dispose();
    _keyFrameManager?.dispose();
  }

  void _updateManager() {
    _manager?.dispose();
    _keyFrameManager?.dispose();

    if (widget.editingAnimation == null) {
      _manager = _keyFrameManager = null;
    } else {
      _manager =
          EditingAnimationManager(widget.editingAnimation, widget.activeFile);
      _keyFrameManager =
          KeyFrameManager(widget.editingAnimation, widget.activeFile);
    }
  }

  @override
  void didUpdateWidget(_EditingAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editingAnimation != widget.editingAnimation ||
        oldWidget.activeFile != widget.activeFile) {
      _updateManager();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _InheritedEditingAnimation(
      editingAnimationManager: _manager,
      child: _InheritedKeyFrameManager(
        keyFrameManager: _keyFrameManager,
        child: widget.child,
      ),
    );
  }
}

class _InheritedKeyFrameManager extends InheritedWidget {
  const _InheritedKeyFrameManager({
    @required this.keyFrameManager,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final KeyFrameManager keyFrameManager;

  @override
  bool updateShouldNotify(_InheritedKeyFrameManager old) =>
      keyFrameManager != old.keyFrameManager;
}

class _InheritedEditingAnimation extends InheritedWidget {
  const _InheritedEditingAnimation({
    @required this.editingAnimationManager,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final EditingAnimationManager editingAnimationManager;

  @override
  bool updateShouldNotify(_InheritedEditingAnimation old) =>
      editingAnimationManager != old.editingAnimationManager;
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
