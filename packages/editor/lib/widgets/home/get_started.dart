import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// Panel showing getting started assets
class GetStartedPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);

    return Container(
      color: theme.colors.panelBackgroundLightGrey,
      child: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Column(
          children: const <Widget>[
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 680,
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: 680,
                    maxWidth: 680,
                    child: Center(
                      child: Text('Get Started'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
