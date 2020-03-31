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

class _Invite {
  final String _name;
  final String _username;
  final String email;

  const _Invite(this._name, this._username, this.email);

  String get name => _name ?? _username;
}

class _TeamMembersState extends State<TeamMembers> {
  final _inviteQueue = <_Invite>[
    _Invite('Luigi Rosso', 'castor', 'luigi@rosso.com'),
    _Invite('Matt Sullivan', 'wolfgang', 'matt@sullivan.com'),
    _Invite(null, null, 'test@email.com'),
  ];
  // final _inviteSuggestions = <String>["Umberto", "Bertoldo", "Zi'mberto"];
  InviteType _selectedInviteType = InviteType.member;

  void _removeInvitee(int index) {
    setState(() {
      _inviteQueue.removeAt(index);
    });
  }

  void _sendInvites() {
    // TODO:
  }

  @override
  Widget build(BuildContext context) {
    final colors = RiveColors();

    final addedSeats = _inviteQueue.length;
    // TODO:
    const occupiedSeats = 1; // widget.team.members.length;
    const teamAvailableSeats = 2; // widget.team.seats;
    final hasRoom = occupiedSeats + addedSeats < teamAvailableSeats;
    final canInvite = _inviteQueue.isNotEmpty && hasRoom;

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
                            for (int i = 0; i < _inviteQueue.length; i++)
                              _UserInvite(
                                  _inviteQueue[i].name ?? _inviteQueue[i].email,
                                  onRemove: () => _removeInvitee(i)),
                            /** ComboBox<String>(
                              value: _inputVal,
                              sizing: ComboSizing.collapsed,
                              typeahead: true,
                              options: _inviteSuggestions,
                              underline: false,
                              valueColor: colors.commonButtonTextColorDark,
                              onInputChanged: _findUserSuggestions,
                              change: (val) {
                                print('Selected $val');
                                setState(() {
                                  _inviteQueue.add()
                                });
                              },
                            ), 
                            */
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
                  onTap: canInvite ? _sendInvites : null,
                  radius: 20,
                )
              ],
            ),
          ))
    ]);
  }
}

class _UserInvite extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;

  const _UserInvite(this.name, {@required this.onRemove});

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
              GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => onRemove(),
                  child: SizedBox(
                    // color: Colors.transparent,
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
