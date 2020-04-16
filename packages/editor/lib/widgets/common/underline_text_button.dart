import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class UnderlineTextButton extends StatelessWidget {
  final String text;
  final Color textColor;
  final VoidCallback onPressed;

  const UnderlineTextButton({
    @required this.text,
    @required this.onPressed,
    this.textColor,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textStyles = RiveTheme.of(context).textStyles;
    return GestureDetector(
        onTap: onPressed,
        child: Text(text,
            style: textStyles.buttonUnderline.copyWith(color: textColor)));
  }
}
