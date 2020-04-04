import 'dart:math' as math;

import 'package:cursor/propagating_listener.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:rive_core/selectable_item.dart';

import 'package:rive_editor/rive/selection_context.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_builders.dart';
import 'package:rive_editor/widgets/listenable_builder.dart';

class InspectorPanel extends StatefulWidget {
  const InspectorPanel({
    Key key,
  }) : super(key: key);

  @override
  _InspectorPanelState createState() => _InspectorPanelState();
}

class _InspectorPanelState extends State<InspectorPanel>
    implements InspectorContext {
  final _scrollController = ScrollController();
  // final _inspector = InspectorContext();
  InspectionSet _lastInspectionSet;
  bool _isFrozen = false;

  @override
  bool get isFrozen => _isFrozen;

  @override
  set isFrozen(bool value) {
    if (value == _isFrozen) {
      return;
    }
    // Ugh. Gotta debounce as sometimes this can be called during the build
    // phase.
    setState(() {
      _isFrozen = value;
    });
  }

  // Ugh. We could call setState, with no changes too...
  void rebuild() => (context as Element).markNeedsBuild();

  final Set<ChangeNotifier> _changeNotifiers = {};

  void _removeListeners() {
    for (final changeNotifier in _changeNotifiers) {
      changeNotifier.removeListener(rebuild);
    }
  }

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = ActiveFile.of(context);
    return Inspector(
      inspector: this,
      child: ColoredBox(
        color: RiveTheme.of(context).colors.panelBackgroundDarkGrey,
        child: ListenableBuilder<SelectionContext<SelectableItem>>(
          listenable: file.selection,
          // Let the builder know it can early out if we're frozen (doesn't
          // prevent building completely but let's us rebuild a little less
          // often).
          condition: (selection) => !_isFrozen,
          builder: (context, selection, _) {
            // Let the inpsection set whittle down groupings and commonly
            // selected coreTypes for the inspector builders to use to
            // determine if there are things they can help inspect.
            var inspectionSet = _isFrozen
                ? _lastInspectionSet
                : InspectionSet.fromSelection(file.core.backboard, selection);
            _lastInspectionSet = inspectionSet;

            // Remove previous listeners, these listen to inspector builders
            // wanting to change the contents in the full inspection list
            // item. Basically any one of them can request a rebuild of the
            // inspection list.
            _removeListeners();

            // Expand the builders and interleave dividers.
            List<WidgetBuilder> builders = [];
            for (int i = 0, builderCount = inspectorBuilders.length;
                i < builderCount;
                i++) {
              var builder = inspectorBuilders[i];

              builder.clean();

              // Is the builder interested in the current inspection set?
              if (!builder.validate(inspectionSet)) {
                continue;
              }

              // Check if the builder can re-expand on demand (useful for
              // InspectorGroups).
              if (builder is ChangeNotifier) {
                var notifier = builder as ChangeNotifier;
                notifier.addListener(rebuild);
                _changeNotifiers.add(notifier);
              }

              var dividerBuilder = InspectorBuilder.divider;
              var expand = builder.expand(inspectionSet);
              if (expand != null && expand.isNotEmpty) {
                builders.addAll(expand);
                if (i != builderCount - 1) {
                  builders.add(dividerBuilder);
                }
              }
            }
            if (builders.isNotEmpty) {
              // At this point we've built a list of builders (no real widgets
              // yet). That's to allow the ListView to build them on demand
              // depending on what's scrolled into view. We take care to make
              // list items the same height (or as similar as possible) in
              // order to gaurantee a smooth scrolling experience when
              // virtualizing lots of items. This is why group expansion works
              // by adding more items to the ListView instead of just creating
              // one large item in the ListView.
              return PropagatingListener(
                behavior: HitTestBehavior.translucent,
                onPointerSignal: (data) {
                  var event = data.pointerEvent as PointerScrollEvent;
                  double delta = event.scrollDelta.dy;
                  var position = _scrollController.position;
                  var newPosition = math.min(
                      math.max(
                          position.pixels + delta, position.minScrollExtent),
                      position.maxScrollExtent);

                  _scrollController.jumpTo(newPosition);
                },
                child: Scrollbar(
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) => builders[index](context),
                    itemCount: builders.length,
                  ),
                ),
              );
            } else {
              // After all our work, no builders were available for this set.
              // Let the user know to select something useful.
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      child: Text(
                        'No Selection',
                        style: RiveTheme.of(context)
                            .textStyles
                            .inspectorWhiteLabel,
                      ),
                    ),
                    Container(height: 10),
                    Container(
                      child: Text(
                        'Select something to view its properties and options.',
                        style: RiveTheme.of(context)
                            .textStyles
                            .inspectorPropertyLabel,
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}

abstract class InspectorContext {
  /// Whether the inspecting set is currently frozen or not.
  bool isFrozen;
}

// class InspectorContext {
//   ValueNotifier<bool> _isFrozen = ValueNotifier<bool>(false);

//   /// Whether the inspecting set is currently frozen or not.
//   bool get isFrozen => _isFrozen.value;
//   set isFrozen(bool value) => _isFrozen.value = value;
// }

class Inspector extends InheritedWidget {
  const Inspector({
    @required this.inspector,
    @required Widget child,
    Key key,
  })  : assert(child != null),
        super(key: key, child: child);

  final InspectorContext inspector;

  static InspectorContext of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Inspector>().inspector;

  @override
  bool updateShouldNotify(Inspector old) => inspector != old.inspector;
}
