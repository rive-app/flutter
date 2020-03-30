import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rive_editor/utils.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/theme.dart';

enum InviteType { member, admin }

class TeamMembers extends StatefulWidget {
  @override
  _TeamMembersState createState() => _TeamMembersState();
}

class _TeamMembersState extends State<TeamMembers> {
  InviteType _selectedInviteType = InviteType.member;

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
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 20),
                const Spacer(),
                ComboBox<InviteType>(
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
                const SizedBox(width: 20),
                FlatIconButton(
                  label: 'Send Invite',
                  color: canInvite
                      ? colors.commonDarkGrey
                      : colors.commonButtonInactiveGrey,
                  textColor:
                      canInvite ? Colors.white : colors.inactiveButtonText,
                  onTap: canInvite
                      ? () {/* TODO: send team invites. */}
                      : null,
                )
              ],
            ),
          ))
    ]);
  }
}
