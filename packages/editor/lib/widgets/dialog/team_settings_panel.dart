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

  @override
  void initState() {
    super.initState();
    _name = 'Rive';
    _username = 'RiveApp';
    _location = 'Moon';
    _website = 'rive.app';
    _bio =
        'Empower creatives through technology that is widely accessible to all.';
    _twitter = 'rive_app';
    _instagram = 'rive.app';
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveThemeData();
    final colors = theme.colors;

    return ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.only(top: 30, left: 30, right: 30),
        children: [
          FormSection(label: 'Account', rows: [
            [
              SettingsTextField(
                label: 'Team Name',
                onChanged: (value) => _name = value,
                initialValue: _name,
              ),
              SettingsTextField(
                label: 'Team Username',
                onChanged: (value) => _username = value,
                initialValue: _username,
              )
            ],
            [
              SettingsTextField(
                label: 'Location',
                hint: 'Where is your team based?',
                onChanged: (value) => _location = value,
                initialValue: _location,
              ),
              SettingsTextField(
                label: 'Website',
                hint: 'Website',
                onChanged: (value) => _website = value,
                initialValue: _website,
              )
            ],
            [
              SettingsTextField(
                label: 'Bio',
                hint: 'Tell users a bit about your team',
                onChanged: (value) => _bio = value,
                initialValue: _bio,
              )
            ]
          ]),
          const SizedBox(height: 30),
          Separator(color: colors.fileLineGrey),
          const SizedBox(height: 30),
          const FormSection(label: 'For Hire', rows: []),
          const SizedBox(height: 30),
          Separator(color: colors.fileLineGrey),
          const SizedBox(height: 30),
          FormSection(label: 'Social', rows: [
            [
              SettingsTextField(
                label: 'Twitter',
                hint: 'Link',
                onChanged: (value) => _twitter = value,
                initialValue: _twitter,
              ),
              SettingsTextField(
                label: 'Instagram',
                hint: 'Link',
                onChanged: (value) => _instagram = value,
                initialValue: _instagram,
              )
            ]
          ]),
        ]);
  }
}

class FormSection extends StatelessWidget {
  final String label;
  final List<List<SettingsTextField>> rows;

  const FormSection({@required this.label, @required this.rows});

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
    const textStyles = TextStyles();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
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
                if (rows.isNotEmpty) ...[
                  _textFieldRow(rows.first),
                  for (final row in rows.sublist(1)) ...[
                    const SizedBox(height: 30),
                    _textFieldRow(row)
                  ]
                ]
              ]),
        )
      ],
    );
  }
}

class SettingsTextField extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final String label;
  final String hint;
  final String initialValue;

  const SettingsTextField(
      {@required this.label, this.hint, this.onChanged, this.initialValue});

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
            initialValue: initialValue,
            keyboardType: TextInputType.multiline,
            minLines: 1,
            maxLines: 5,
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
