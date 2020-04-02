import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class RoundedSection extends StatelessWidget {
  final WidgetBuilder contentBuilder;
  final Color background;

  const RoundedSection({this.contentBuilder, this.background, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    return DecoratedBox(
        decoration: BoxDecoration(
            color: colors.fileBackgroundLightGrey,
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
            padding: const EdgeInsets.all(20), child: contentBuilder(context)));
  }
}
