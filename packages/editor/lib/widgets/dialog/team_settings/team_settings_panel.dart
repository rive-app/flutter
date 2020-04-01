import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/rive_radio.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_text_field.dart';
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
  bool _isForHire;

  @override
  void initState() {
    super.initState();
    _name = 'Rive';
    _username = 'RiveApp';
    _location = 'Moon';
    _website = 'rive.app';
    _twitter = 'rive_app';
    _instagram = 'rive.app';
    _isForHire = false;
  }

  void _submitChanges() {
    // TODO: 
  }

  void _updateForHire(bool newValue) {
    if (_isForHire == newValue) return;
    setState(() {
      _isForHire = newValue;
    });
  }

  Widget _textFieldRow(List<SettingsTextField> textFields) {
    if (textFields.isEmpty) {
      return const SizedBox();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: textFields.first),
        for (final textField in textFields.sublist(1)) ...[
          const SizedBox(width: 30),
          Expanded(child: textField)
        ]
      ],
    );
  }

  Widget _formSection(String label, List<List<SettingsTextField>> rows) {
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

  @override
  Widget build(BuildContext context) {
    final theme = RiveThemeData();
    final colors = theme.colors;
    const textStyles = TextStyles();

    return Column(
      // Stretches the two separators
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(30),
              children: [
                _formSection('Account', [
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'For Hire',
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
                            LabeledRadio(
                                label: 'Available For Hire',
                                groupValue: _isForHire,
                                value: true,
                                onChanged: _updateForHire),
                            Padding(
                              // Padding: 20 (radio button) + 10 text padding
                              padding: const EdgeInsets.only(left: 30.0),
                              // TODO: add link to the "artists for hire". 
                              // What will it link to?
                              child: Text(
                                  'Allow other users to message you about work'
                                  ' opportunities. You will also show up in our list'
                                  ' of artists for hire.',
                                  style: textStyles.hierarchyTabHovered
                                      .copyWith(fontSize: 13, height: 1.6)),
                            ),
                            const SizedBox(height: 24),
                            LabeledRadio(
                                label: 'Not Available For Hire',
                                groupValue: _isForHire,
                                value: false,
                                onChanged: _updateForHire),
                            const SizedBox(width: 30),
                            Padding(
                              // Padding: 20 (radio button) + 10 text padding
                              padding: const EdgeInsets.only(left: 30.0),
                              child: Text(
                                  "Don't allow other users to contact you about"
                                  ' work opportunities.',
                                  style: textStyles.hierarchyTabHovered
                                      .copyWith(fontSize: 13, height: 1.6)),
                            )
                          ]),
                    )
                  ],
                ),
                const SizedBox(height: 30),
                Separator(color: colors.fileLineGrey),
                const SizedBox(height: 30),
                _formSection('Social', [
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
                ])
              ]),
        ),
        Separator(color: colors.fileLineGrey),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: FlatIconButton(
                    label: 'Save Changes',
                    color: colors.commonDarkGrey,
                    textColor: Colors.white,
                    onTap: _submitChanges))
          ],
        )
      ],
    );
  }
}

class LabeledRadio extends StatelessWidget {
  final String label;
  final bool groupValue;
  final bool value;
  final ValueChanged<bool> onChanged;

  const LabeledRadio({
    @required this.label,
    @required this.groupValue,
    @required this.onChanged,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = RiveColors();
    const styles = TextStyles();
    return GestureDetector(
      onTap: () {
        if (value != groupValue) onChanged(value);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          RiveRadio<bool>(
            groupValue: groupValue,
            value: value,
            onChanged: onChanged,
            selectedColor: colors.commonDarkGrey,
          ),
          const SizedBox(width: 10),
          Text(label, style: styles.greyText),
        ],
      ),
    );
  }
}
