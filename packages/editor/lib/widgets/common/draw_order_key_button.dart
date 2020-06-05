import 'package:core/key_state.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_editor/rive/managers/animation/editing_animation_manager.dart';
import 'package:rive_editor/widgets/common/key_state_button.dart';

class DrawOrderKeyButton extends StatelessWidget {
  final EditingAnimationManager manager;

  const DrawOrderKeyButton({
    @required this.manager,
    Key key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: manager.animation.artboard.drawOrderKeyStateListenable,
      builder: (context, KeyState keyState, _) => KeyStateButton(
        keyState: keyState,
        setKey: () {
          manager.keyComponents.add(
            KeyComponentsEvent(
                components: [manager.animation.artboard],
                propertyKey: DrawableBase.drawOrderPropertyKey),
          );
        },
      ),
    );
  }
}
