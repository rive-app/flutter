import 'package:cursor/propagating_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/editor_alert.dart';
import 'package:rive_editor/widgets/common/animated_factor_builder.dart';
import 'package:rive_editor/widgets/common/hit_deny.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class AlertsDisplay extends StatefulWidget {
  @override
  _AlertsDisplayState createState() => _AlertsDisplayState();
}

class _AlertsDisplayState extends State<AlertsDisplay> {
  final Set<EditorAlert> _lastAlerts = {};

  @override
  Widget build(BuildContext context) {
    final file = ActiveFile.of(context);
    return ValueListenableBuilder<Iterable<EditorAlert>>(
      valueListenable: file.alerts,
      builder: (context, alerts, _) {
        var alertSet = Set<EditorAlert>.from(alerts);
        _lastAlerts.addAll(alerts);

        var display = _lastAlerts.toList().reversed;

        return HitDeny(
          // Hit deny to prevent clicking on scroll view (we need to hit the
          // stage back there). Each alert display will hit allow. We need a
          // scroll view here in case we get sooo many alerts and still want to
          // be able to mousewheel through them.
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final alert in display)
                  AlertDisplay(
                    key: ValueKey(alert),
                    alert: alert,
                    isVisible: alertSet.contains(alert),
                    hidden: () {
                      setState(
                        () {
                          _lastAlerts.remove(alert);
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AlertDisplay extends StatelessWidget {
  final EditorAlert alert;
  final bool isVisible;
  final VoidCallback hidden;

  const AlertDisplay({
    Key key,
    this.alert,
    this.isVisible,
    this.hidden,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return HitAllow(
      child: PropagatingListener(
        onPointerDown: (details) {
          if (alert.dismissOnPress) {
            alert.dismiss();
          }
        },
        child: ClipRect(
          child: AnimatedFactorBuilder(
            factor: isVisible ? 1 : 0,
            builder: (context, factor, child) => Align(
              heightFactor: factor,
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: alert.build(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
