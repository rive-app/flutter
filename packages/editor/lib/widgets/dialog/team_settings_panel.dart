import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/theme.dart';

class TeamSettings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TeamSettingsState();
}

class _TeamSettingsState extends State<TeamSettings> {
  String _name;
  String _username;
  String _location;
  String _website;
  String _bio;
  String _twitter;
  String _instagram;

  Widget _textFieldRow(List<SettingsTextField> textFields) {
    if (textFields.isEmpty) {
      return const SizedBox();
    }

    return Row(
      children: <Widget>[
        Expanded(child: textFields.first),
        // Use 'collection-for' in tandem with the spread operator
        // to add multiple widgets at once.
        for (final textField in textFields.sublist(1)) ...[
          const SizedBox(width: 30),
          Expanded(child: textField)
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveThemeData();
    final colors = theme.colors;
    final textStyles = theme.textStyles;
    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.only(top: 30, left: 30, right: 30),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Account',
                  style: textStyles.fileGreyTextLarge,
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 75,
                    maxWidth: 390,
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _textFieldRow([
                          SettingsTextField(
                            label: 'Team Name',
                            onChanged: (value) => _name = value,
                          ),
                          SettingsTextField(
                              label: 'Team Username',
                              onChanged: (value) => _username = value)
                        ]),
                        const SizedBox(height: 30),
                        _textFieldRow([
                          SettingsTextField(
                              label: 'Location',
                              hint: 'Where is your team based?',
                              onChanged: (value) => _location = value),
                          SettingsTextField(
                              label: 'Website',
                              hint: 'www.myteam.com',
                              onChanged: (value) => _website = value),
                        ]),
                        const SizedBox(height: 30),
                        _textFieldRow([
                          SettingsTextField(
                              label: 'Bio',
                              hint: 'Tell users a bit about your team',
                              onChanged: (value) => _bio = value),
                        ])
                      ]),
                )
              ],
            ),
            const SizedBox(height: 30),
            Separator(color: colors.fileLineGrey),
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'For Hire',
                  style: textStyles.fileGreyTextLarge,
                ),
                Column(children: [
                  Row(
                    children: [],
                  )
                ])
              ],
            ),
            Separator(color: colors.fileLineGrey),
            const SizedBox(height: 30),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Social',
                  style: textStyles.fileGreyTextLarge,
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 75,
                    maxWidth: 390,
                  ),
                  child: _textFieldRow(
                    [
                      SettingsTextField(
                        label: 'Twitter',
                        hint: 'Link',
                        onChanged: (value) => _twitter = value,
                      ),
                      SettingsTextField(
                        label: 'Instagram',
                        hint: 'Link',
                        onChanged: (value) => _instagram = value,
                      )
                    ],
                  ),
                )
              ],
            )
          ]),
    ));
  }
}

class SettingsTextField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String label;
  final String hint;

  const SettingsTextField({@required this.label, this.hint, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = RiveColors();
    const textStyles = TextStyles();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(label,
            style: textStyles.hierarchyTabInactive.copyWith(fontSize: 13)),
        const SizedBox(height: 11),
        TextFormField(
            onChanged: onChanged,
            cursorColor: colors.commonDarkGrey,
            textAlign: TextAlign.left,
            decoration: InputDecoration(
              isDense: true,
              hintText: hint,
              hintStyle: textStyles.textFieldInputHint.copyWith(fontSize: 13),
              contentPadding: const EdgeInsets.only(bottom: 2),
              focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors.commonDarkGrey)),
            ),
            style: textStyles.fileGreyTextLarge),
      ],
    );
  }
}
