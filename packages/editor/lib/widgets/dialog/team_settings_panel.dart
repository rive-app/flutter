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
              TextFieldData()
                ..label = 'Team Name'
                ..callback = (value) => _name = value,
              TextFieldData()
                ..label = 'Team Username'
                ..callback = (value) => _username = value
            ],
            [
              TextFieldData()
                ..label = 'Location'
                ..hint = 'Where is your team based?'
                ..callback = (value) => _location = value,
              TextFieldData()
                ..label = 'Website'
                ..hint = 'Website'
                ..callback = (value) => _website = value
            ],
            [
              TextFieldData()
                ..label = 'Bio'
                ..hint = 'Tell users a bit about your team'
                ..callback = (value) => _bio = value
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
              TextFieldData()
                ..label = 'Twitter'
                ..hint = 'Link'
                ..callback = (value) => _twitter = value,
              TextFieldData()
                ..label = 'Instagram'
                ..hint = 'Link'
                ..callback = (value) => _instagram = value,
            ]
          ]),
        ]);
  }
}

class TextFieldData {
  String label;
  String hint;
  ValueChanged<String> callback;
}

class FormSection extends StatelessWidget {
  final String label;
  final List<List<TextFieldData>> rows;

  const FormSection({@required this.label, @required this.rows});

  Widget _textFieldRow(List<TextFieldData> textFieldData) {
    if (textFieldData.isEmpty) {
      return const SizedBox();
    }

    final textFields = textFieldData
        .map((data) => SettingsTextField(
            label: data.label, onChanged: data.callback, hint: data.hint))
        .toList();

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
