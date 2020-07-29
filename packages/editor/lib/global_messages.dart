import 'package:core/debounce.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/alerts_display.dart';
import 'package:rive_editor/rive/alerts/click_alert.dart';
import 'package:rive_editor/rive/alerts/simple_alert.dart';
import 'package:rive_editor/widgets/common/hit_deny.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';

class GlobalMessages extends StatefulWidget {
  @override
  _GlobalMessagesState createState() => _GlobalMessagesState();
}

class _GlobalMessagesState extends State<GlobalMessages> {
  void _rebuild() {
    (context as StatefulElement).markNeedsBuild();
  }

  @override
  void dispose() {
    cancelDebounce(_rebuild);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder<GlobalMessage>(
      stream: Plumber().getStream<GlobalMessage>(),
      builder: (context, message) {
        if (message.data == null) {
          return const SizedBox();
        }

        var alert = (message.data.callback != null)
            ? ClickAlert(message.data.message, message.data.actionLabel,
                message.data.callback)
            : SimpleAlert(message.data.message);

        return HitDeny(
          // Hit deny to prevent clicking on scroll view (we need to hit the
          // stage back there). Each alert display will hit allow. We need a
          // scroll view here in case we get sooo many alerts and still want to
          // be able to mousewheel through them.
          child: SingleChildScrollView(
              child: AlertDisplay(
                  key: const ValueKey('neo'),
                  alert: alert,
                  isVisible: true,
                  topPadding: 40)),
        );
      },
    );
  }
}
