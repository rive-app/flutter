import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';

/// An editor building function which is expected to return a list of builders
/// based on the current inspecting set. Note that this returns a list of
/// [WidgetBuilder]s so that a virtualized ListView can be built, preventing
/// every widget in a potentially very large inspector panel from built at once.
typedef InspectorExpander = List<WidgetBuilder> Function(InspectionSet);

abstract class InspectorBuilder {
  /// Validate must ensure that the inspecting set has sensible data that the
  /// expander can work with.
  bool validate(InspectionSet inspecting);

  /// Gauranteed to be called only when sensible data is available.
  List<WidgetBuilder> expand(InspectionSet inspecting);

  /// Reset any listeners that may have gotten previously subscribed.
  void clean() {}

  /// Builder for the divider.
  static Widget divider(BuildContext context) => Separator(
        padding: const EdgeInsets.only(
          left: 20,
          top: 10,
          bottom: 10,
        ),
        color: RiveTheme.of(context).colors.inspectorSeparator,
      );
}

/// A listening ispector builder which will rebuild when any of the items it's
/// listening to notify.
abstract class ListenableInspectorBuilder extends InspectorBuilder
    with ChangeNotifier {
  final Set<Listenable> _notifiers = {};

  @override
  void clean() {
    for (final notifier in _notifiers) {
      notifier.removeListener(notifyListeners);
    }
    _notifiers.clear();
  }

  /// Propagate changes from one set of notifiers to this inspector.
  void changeWhen(Iterable<Listenable> notifiers) {
    for (final notifier in notifiers) {
      if (_notifiers.add(notifier)) {
        notifier.addListener(notifyListeners);
      }
    }
  }
}
