import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/theme.dart';

class TeamSettings extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _TeamSettingsState();
}

class _TeamSettingsState extends State<TeamSettings> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  final _bioController = TextEditingController();
  final _twitterController = TextEditingController();
  final _instagramController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _bioController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    super.dispose();
  }

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
                              label: 'Team Name', controller: _nameController),
                          SettingsTextField(
                              label: 'Team Username',
                              controller: _usernameController),
                        ]),
                        const SizedBox(height: 30),
                        _textFieldRow([
                          SettingsTextField(
                              label: 'Location',
                              hint: 'Where is your team based?',
                              controller: _locationController),
                          SettingsTextField(
                              label: 'Website',
                              hint: 'www.myteam.com',
                              controller: _websiteController),
                        ]),
                        const SizedBox(height: 30),
                        _textFieldRow([
                          SettingsTextField(
                              label: 'Bio',
                              hint: 'Tell users a bit about your team',
                              controller: _bioController),
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
                        controller: _twitterController,
                      ),
                      SettingsTextField(
                        label: 'Instagram',
                        hint: 'Link',
                        controller: _instagramController,
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
  final TextEditingController controller;
  final String label;
  final String hint;

  const SettingsTextField(
      {@required this.controller, @required this.label, this.hint});

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
            cursorColor: colors.commonDarkGrey,
            textAlign: TextAlign.left,
            controller: controller,
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
