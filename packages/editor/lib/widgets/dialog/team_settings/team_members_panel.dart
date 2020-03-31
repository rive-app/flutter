import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

enum InviteType { member, admin }

class TeamMembers extends StatefulWidget {
  @override
  _TeamMembersState createState() => _TeamMembersState();
}

class _TeamMembersState extends State<TeamMembers> {
  InviteType _selectedInviteType = InviteType.member;
  final _invitees = <String>[
    "email@domain.com",
    "example@domain.com",
    "Max Talbot",
    "Umberto Sonnino",
    "Cruz Santana",
    "Robert Haynie",
    "Luigi Green"
  ];

  void _removeInvitee(int index) {
    setState(() {
      _invitees.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = RiveColors();

    // TODO:
    // final canInvite = occupiedSeats + addedSeats < teamSize;
    final canInvite = false;

    return ListView(padding: const EdgeInsets.all(30), children: [
      DecoratedBox(
          decoration: BoxDecoration(
              color: colors.fileBackgroundLightGrey,
              borderRadius: BorderRadius.circular(10)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Wrap(
                          alignment: WrapAlignment.start,
                          crossAxisAlignment: WrapCrossAlignment.start,
                          direction: Axis.horizontal,
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (int i = 0; i < _invitees.length; i++)
                              _Invitee(_invitees[i],
                                  onRemove: () => _removeInvitee(i))
                          ]),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  height: 30,
                  child: Center(
                    child: ComboBox<InviteType>(
                      value: _selectedInviteType,
                      change: (type) => setState(() {
                        _selectedInviteType = type;
                      }),
                      alignment: Alignment.topRight,
                      options: InviteType.values,
                      toLabel: (option) => describeEnum(option).capsFirst,
                      popupWidth: 116,
                      underline: false,
                      valueColor: colors.fileBackgroundDarkGrey,
                      sizing: ComboSizing.content,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                FlatIconButton(
                  label: 'Send Invite',
                  color: canInvite
                      ? colors.commonDarkGrey
                      : colors.commonButtonInactiveGrey,
                  textColor:
                      canInvite ? Colors.white : colors.inactiveButtonText,
                  onTap: canInvite ? () {/* TODO: send team invites. */} : null,
                  radius: 20,
                )
              ],
            ),
          ))
    ]);
  }
}

class _Invitee extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;

  const _Invitee(this.name, {@required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final colors = RiveColors();
    const styles = TextStyles();
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
              ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 315),
                  child: Text(name,
                      style: styles.popupShortcutText,
                      overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 10),
              Listener(
                  onPointerDown: (_) => onRemove(),
                  child: Container(
                    color: Colors.transparent,
                    child: Center(
                      child: TintedIcon(
                          color: colors.commonButtonTextColor, icon: 'delete'),
                    ),
                  ))
            ]),
      ),
    );
  }
}
