import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/theme.dart';

class RoundedSection extends StatelessWidget {
  final WidgetBuilder contentBuilder;
  final Color background;

  const RoundedSection({this.contentBuilder, this.background, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = RiveColors();
    return DecoratedBox(
        decoration: BoxDecoration(
            color: colors.fileBackgroundLightGrey,
            borderRadius: BorderRadius.circular(10)),
        child: Padding(
            padding: const EdgeInsets.all(20), child: contentBuilder(context)));
  }
}
