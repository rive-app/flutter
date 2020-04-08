import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/models/owner.dart';
import 'package:rive_api/models/profile.dart';
import 'package:rive_api/models/team.dart';
import 'package:rive_api/profiles.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/rive_radio.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/dialog/team_settings/panel_section.dart';
import 'package:rive_editor/widgets/dialog/team_settings/settings_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class ProfileSettings extends StatefulWidget {
  final RiveOwner owner;
  final RiveApi api;
  const ProfileSettings(this.owner, this.api);

  @override
  State<StatefulWidget> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  ProfilePackage _profile;
  RiveProfilesApi _profilesApi;

  @override
  void initState() {
    super.initState();

    final owner = widget.owner;

    _profilesApi = RiveProfilesApi(widget.api);
    ProfilePackage.getProfile(widget.api, owner).then((value) {
      setState(() {
        _profile = value;
        _profile.addListener(_onProfileChange);
      });
    });
  }

  @override
  void dispose() {
    _profile.dispose();
    super.dispose();
  }

  void _onProfileChange() => setState(() {});

  void _submitChanges() {
    _profile.submitChanges(
        widget.api, widget.owner); //.then((value) => /** TODO: */);
  }

  Widget _textFieldRow(List<Widget> children) {
    if (children.isEmpty) {
      return const SizedBox();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(child: children.first),
        for (final child in children.sublist(1)) ...[
          const SizedBox(width: 30),
          Expanded(child: child)
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // TODO: use FutureBuilder?
    if (_profile == null) {
      return const SizedBox();
    }
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final textStyles = theme.textStyles;
    var labelPrefix = widget.owner is RiveTeam ? 'Team ' : '';

    return Column(
      // Stretches the separators
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(30),
              children: [
                SettingsPanelSection(
                    label: 'Account',
                    contents: (panelContext) => Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _textFieldRow([
                                SettingsTextField(
                                  label: '${labelPrefix}Name',
                                  onChanged: (value) => _profile.name = value,
                                  initialValue: _profile.name,
                                ),
                                SettingsTextField(
                                  label: '${labelPrefix}Username',
                                  onChanged: (value) =>
                                      _profile.username = value,
                                  initialValue: _profile.username,
                                )
                              ]),
                              const SizedBox(height: 30),
                              _textFieldRow(
                                [
                                  SettingsTextField(
                                    label: 'Location',
                                    hint: 'Where is your team based?',
                                    onChanged: (value) =>
                                        _profile.location = value,
                                    initialValue: _profile.location,
                                  ),
                                  SettingsTextField(
                                    label: 'Website',
                                    hint: 'Website',
                                    onChanged: (value) =>
                                        _profile.website = value,
                                    initialValue: _profile.website,
                                  )
                                ],
                              ),
                              const SizedBox(height: 30),
                              _textFieldRow([
                                SettingsTextField(
                                  label: 'Bio',
                                  hint: 'Tell users a bit about your team',
                                  onChanged: (value) => _profile.blurb = value,
                                  initialValue: _profile.blurb,
                                )
                              ])
                            ])),
                const SizedBox(height: 30),
                Separator(color: colors.fileLineGrey),
                const SizedBox(height: 30),
                SettingsPanelSection(
                  label: 'For Hire',
                  contents: (panelContext) => Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LabeledRadio(
                            label: 'Available For Hire',
                            groupValue: _profile.isForHire,
                            value: true,
                            onChanged: (value) => _profile.isForHire = value),
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
                            groupValue: _profile.isForHire,
                            value: false,
                            onChanged: (value) => _profile.isForHire = value),
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
                ),
                const SizedBox(height: 30),
                Separator(color: colors.fileLineGrey),
                const SizedBox(height: 30),
                SettingsPanelSection(
                  label: 'Social',
                  contents: (panelContext) => Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _textFieldRow([
                          SettingsTextField(
                            label: 'Twitter',
                            hint: 'Link',
                            onChanged: (value) => _profile.twitter = value,
                            initialValue: _profile.twitter,
                          ),
                          SettingsTextField(
                            label: 'Instagram',
                            hint: 'Link',
                            onChanged: (value) => _profile.instagram = value,
                            initialValue: _profile.instagram,
                          )
                        ]),
                        const SizedBox(height: 30),
                        _textFieldRow([
                          SettingsTextField(
                            label: 'Dribbble',
                            hint: 'Link',
                            onChanged: (value) => _profile.dribbble = value,
                            initialValue: _profile.dribbble,
                          ),
                          SettingsTextField(
                            label: 'LinkedIn',
                            hint: 'Link',
                            onChanged: (value) => _profile.linkedin = value,
                            initialValue: _profile.linkedin,
                          )
                        ]),
                        const SizedBox(height: 30),
                        _textFieldRow([
                          SettingsTextField(
                            label: 'Behance',
                            hint: 'Link',
                            onChanged: (value) => _profile.behance = value,
                            initialValue: _profile.behance,
                          ),
                          SettingsTextField(
                            label: 'Vimeo',
                            hint: 'Link',
                            onChanged: (value) => _profile.vimeo = value,
                            initialValue: _profile.vimeo,
                          )
                        ]),
                        const SizedBox(height: 30),
                        _textFieldRow([
                          SettingsTextField(
                            label: 'GitHub',
                            hint: 'Link',
                            onChanged: (value) => _profile.github = value,
                            initialValue: _profile.github,
                          ),
                          SettingsTextField(
                            label: 'Medium',
                            hint: 'Link',
                            onChanged: (value) => _profile.medium = value,
                            initialValue: _profile.medium,
                          )
                        ]),
                      ]),
                ),
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
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;

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

class ProfilePackage with ChangeNotifier {
  RiveProfile _profile;

  ProfilePackage();

  // Initializer for this profile.
  static Future<ProfilePackage> getProfile(RiveApi api, RiveOwner owner) async {
    var response = await RiveProfilesApi(api).getInfo(owner);
    if (response != null) {
      return ProfilePackage().._profile = response;
    }
    return null;
  }

  Future<void> submitChanges(RiveApi api, RiveOwner owner) async {
    var response =
        await RiveProfilesApi(api).updateInfo(owner, profile: _profile);
  }

  String get name => _profile.name;
  set name(String value) {
    if (value == _profile.name) return;
    _profile.name = value;
    notifyListeners();
  }

  String get username => _profile.username;
  set username(String value) {
    if (value == _profile.username) return;
    _profile.username = value;
    notifyListeners();
  }

  String get location => _profile.location;
  set location(String value) {
    if (value == _profile.location) return;
    _profile.location = value;
    notifyListeners();
  }

  String get website => _profile.website;
  set website(String value) {
    if (value == _profile.website) return;
    _profile.website = value;
    notifyListeners();
  }

  String get blurb => _profile.blurb;
  set blurb(String value) {
    if (value == _profile.blurb) return;
    _profile.blurb = value;
    notifyListeners();
  }

  String get twitter => _profile.twitter;
  set twitter(String value) {
    if (value == _profile.twitter) return;
    _profile.twitter = value;
    notifyListeners();
  }

  String get instagram => _profile.instagram;
  set instagram(String value) {
    if (value == _profile.instagram) return;
    _profile.instagram = value;
    notifyListeners();
  }

  String get dribbble => _profile.dribbble;
  set dribbble(String value) {
    if (value == _profile.dribbble) return;
    _profile.dribbble = value;
    notifyListeners();
  }

  String get linkedin => _profile.linkedin;
  set linkedin(String value) {
    if (value == _profile.linkedin) return;
    _profile.linkedin = value;
    notifyListeners();
  }

  String get behance => _profile.behance;
  set behance(String value) {
    if (value == _profile.behance) return;
    _profile.behance = value;
    notifyListeners();
  }

  String get vimeo => _profile.vimeo;
  set vimeo(String value) {
    if (value == _profile.vimeo) return;
    _profile.vimeo = value;
    notifyListeners();
  }

  String get github => _profile.github;
  set github(String value) {
    if (value == _profile.github) return;
    _profile.github = value;
    notifyListeners();
  }

  String get medium => _profile.medium;
  set medium(String value) {
    if (value == _profile.medium) return;
    _profile.medium = value;
    notifyListeners();
  }

  bool get isForHire => _profile.isForHire;
  set isForHire(bool value) {
    if (value == _profile.isForHire) return;
    _profile.isForHire = value;
    notifyListeners();
  }
}
