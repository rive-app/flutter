import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/editor_alert.dart';
import 'package:rive_editor/widgets/common/animated_factor_builder.dart';
import 'package:rive_editor/widgets/common/fractional_intrinsic_height.dart';
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
        return ClipRect(
          child: Column(
            children: [
              for (final alert in _lastAlerts.toList().reversed)
                AlertDisplay(
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
    return AnimatedFactorBuilder(
      factor: isVisible ? 1 : 0,
      builder: (context, factor, child) => FractionalIntrinsicHeight(
        heightFactor: factor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: alert.build(context),
        ),
      ),
    );
  }
}
