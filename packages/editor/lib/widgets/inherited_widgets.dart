import 'package:flutter/widgets.dart';
import 'package:rive_core/animation/linear_animation.dart';
import 'package:rive_core/artboard.dart';

import 'package:rive_editor/rive/icon_cache.dart';
import 'package:rive_editor/rive/managers/animations_manager.dart';
import 'package:rive_editor/rive/managers/editing_animation_manager.dart';
import 'package:rive_editor/rive/managers/follow_manager.dart';
import 'package:rive_editor/rive/managers/notification_manager.dart';
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

// Notifications state manager

class NotificationProvider extends StatefulWidget {
  const NotificationProvider({@required this.manager, this.child});
  final Widget child;
  final NotificationManager manager;

  @override
  _NotificationProviderState createState() => _NotificationProviderState();

  static NotificationManager of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedNotificationProvider>()
      .manager;
}

class _NotificationProviderState extends State<NotificationProvider> {
  NotificationManager _manager;

  @override
  void initState() {
    _manager = widget.manager;
    super.initState();
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _InheritedNotificationProvider(
        manager: _manager,
        child: widget.child,
      );
}

class _InheritedNotificationProvider extends InheritedWidget {
  const _InheritedNotificationProvider({
    @required this.manager,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final NotificationManager manager;

  @override
  bool updateShouldNotify(_InheritedNotificationProvider old) =>
      manager != old.manager;
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
      .manager;
}

class _AnimationsProviderState extends State<AnimationsProvider> {
  AnimationsManager _manager;

  @override
  void initState() {
    _manager = widget.activeArtboard == null
        ? null
        : AnimationsManager(activeArtboard: widget.activeArtboard);
    super.initState();
  }

  @override
  void didUpdateWidget(AnimationsProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeArtboard != widget.activeArtboard) {
      _manager = widget.activeArtboard == null
          ? null
          : AnimationsManager(activeArtboard: widget.activeArtboard);
    }
  }

  @override
  void dispose() {
    _manager.dispose();
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
  Widget build(BuildContext context) => StreamBuilder<AnimationViewModel>(
        stream: AnimationsProvider.of(context).selectedAnimation,
        builder: (context, snapshot) => _InheritedEditingAnimation(
          child: child,
          editingAnimationManager:
              snapshot.hasData && snapshot.data.animation is LinearAnimation
                  ? EditingAnimationManager(
                      snapshot.data.animation as LinearAnimation)
                  : null,
        ),
      );

  static EditingAnimationManager of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedEditingAnimation>()
      .editingAnimationManager;
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
