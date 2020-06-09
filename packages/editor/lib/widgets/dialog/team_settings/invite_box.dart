import 'package:flutter/material.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:rive_editor/widgets/toolbar/connected_users.dart';

class InviteBox extends StatelessWidget {
  const InviteBox(
    this.name, {
    @required this.onRemove,
    this.isSelected = false,
  });

  final String name;
  final VoidCallback onRemove;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isSelected ? colors.commonDarkGrey : null,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: colors.commonButtonTextColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 315),
                child: Text(
                  name,
                  style: styles.popupShortcutText.copyWith(
                    fontFamily: 'Roboto-Regular',
                    height: 1.15,
                    color: isSelected ? Colors.white : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                      color: isSelected
                          ? Colors.white
                          : colors.commonButtonTextColor,
                      icon: PackedIcon.delete,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

abstract class Invite {
  Invite();
  String get label;
  String get inviteBoxLabel;

  WidgetBuilder leadingWidget;
}

class UserInvite extends Invite {
  UserInvite({
    @required this.ownerId,
    @required this.name,
    @required this.username,
    @required this.avatarUrl,
  });

  final int ownerId;
  final String name;
  final String username;
  final String avatarUrl;

  @override
  String get label => '${name != null ? name + ' ' : ''}'
      '${username != null ? '@' + username : ''}';

  @override
  String get inviteBoxLabel => name ?? username;

  @override
  WidgetBuilder get leadingWidget => (_) {
        return Padding(
          padding: const EdgeInsets.only(right: 5),
          child: AvatarView(
            diameter: 20,
            borderWidth: 0,
            imageUrl: avatarUrl,
            name: name ?? username,
            color: Colors.transparent,
          ),
        );
      };
}

class EmailInvite extends Invite {
  EmailInvite(this.email);

  final String email;

  @override
  String get label => email;

  @override
  String get inviteBoxLabel => email;

  @override
  WidgetBuilder get leadingWidget => (context) {
        final colors = RiveTheme.of(context).colors;
        return Padding(
          padding: const EdgeInsets.only(right: 5),
          // Constrain size to let ComboBox calculate width properly.
          child: SizedBox(
            width: 20,
            height: 20,
            child: TintedIcon(
              icon: PackedIcon.hire,
              color: colors.fileIconColor,
            ),
          ),
        );
      };
}
