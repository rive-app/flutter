import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class UserInviteBox extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;

  const UserInviteBox(this.name, {@required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;

    return DecoratedBox(
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: colors.commonButtonTextColor)),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 315),
                    child: Text(name,
                        style: styles.popupShortcutText.copyWith(
                            fontFamily: 'Roboto-Regular', height: 1.15),
                        overflow: TextOverflow.ellipsis)),
              ),
              const SizedBox(width: 10),
              Center(
                child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (_) => onRemove(),
                    child: SizedBox(
                      // color: Colors.transparent,
                      child: Center(
                        child: TintedIcon(
                            color: colors.commonButtonTextColor,
                            icon: 'delete'),
                      ),
                    )),
              )
            ]),
      ),
    );
  }
}

abstract class Invite {
  const Invite();
  String get name;
}

class UserInvite extends Invite {
  final int ownerId;
  @override
  final String name;

  const UserInvite(this.ownerId, this.name);
}

class EmailInvite extends Invite {
  final String email;

  const EmailInvite(this.email);

  @override
  String get name => email;
}