import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class AnimationToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(children: [TintedIcon(icon:'play'), TintedIcon(icon:'to-start'), TintedIcon(icon:'loop')],);
  }
}
