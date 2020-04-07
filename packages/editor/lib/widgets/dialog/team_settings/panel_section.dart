
import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class SettingsPanelSection extends StatelessWidget {
  final String label;
  final WidgetBuilder contents;

  const SettingsPanelSection({@required this.label, this.contents, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyles = RiveTheme.of(context).textStyles;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: textStyles.fileGreyTextLarge,
        ),
        const Spacer(),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 75,
            maxWidth: 393,
          ),
          child: contents(context),
        )
      ],
    );
  }
}
