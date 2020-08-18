import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/labeled_text_field.dart';
import 'package:rive_editor/widgets/common/rive_radio.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/common/value_stream_builder.dart';
import 'package:rive_editor/widgets/dialog/team_settings/panel_section.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// This is the Profile panel for an [owner].
/// Owner can be a [Team] or a [Me] user.
///
/// Users will have fields to change their email and password.
///

final _emailRegEx = RegExp(
    r'''(?:[a-z0-9!#\$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#\$%&'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])''');

class ProfileSettings extends StatefulWidget {
  final Owner owner;
  const ProfileSettings(this.owner);

  @override
  State<StatefulWidget> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  StreamSubscription<Profile> _profileSubscription;

  @override
  void initState() {
    super.initState();
    ProfileManager().loadProfile(widget.owner);
  }

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder<Profile>(
      stream: Plumber().getStream<Profile>(widget.owner.ownerId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final profile = snapshot.data;
          return ProfileSettingsInner(profile: profile, owner: widget.owner);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class OwnerPackage with ChangeNotifier {
  /// The team data.
  final bool isTeam;
  String _name;
  String _username;
  String _email;
  String _location;
  String _website;
  String _bio;
  String _twitter;
  String _instagram;
  String _dribbble;
  String _linkedin;
  String _behance;
  String _vimeo;
  String _github;
  String _medium;
  bool _isForHire;

  String nameValidationError;
  String usernameValidationError;
  String emailValidationError;

  bool processing = false;

  OwnerPackage(
      {String name,
      String username,
      String email,
      String location = '',
      String website = '',
      String bio = '',
      String instagram = '',
      String dribbble = '',
      String twitter = '',
      String linkedin = '',
      String behance = '',
      String vimeo = '',
      String github = '',
      String medium = '',
      bool isForHire = false,
      this.isTeam})
      : _name = name,
        _username = username,
        _email = email,
        _location = location,
        _website = website,
        _bio = bio,
        _instagram = instagram,
        _dribbble = dribbble,
        _behance = behance,
        _linkedin = linkedin,
        _twitter = twitter,
        _vimeo = vimeo,
        _github = github,
        _medium = medium,
        _isForHire = isForHire;

  String get name => _name;
  String get username => _username;
  String get email => _email;
  String get location => _location;
  String get website => _website;
  String get bio => _bio;
  String get twitter => _twitter;
  String get instagram => _instagram;
  String get dribbble => _dribbble;
  String get linkedin => _linkedin;
  String get behance => _behance;
  String get vimeo => _vimeo;
  String get github => _github;
  String get medium => _medium;
  bool get isForHire => _isForHire;

  set isForHire(bool isForHire) {
    if (_isForHire == isForHire) return;
    _isForHire = isForHire;
    notifyListeners();
  }

  set name(String name) {
    if (_name == name) return;
    _name = name;
    notifyListeners();
  }

  set username(String username) {
    if (_username == username) return;
    _username = username;
    notifyListeners();
  }

  set email(String email) {
    if (_email == email) return;
    _email = email;
    notifyListeners();
  }

  set location(String location) {
    if (_location == location) return;
    _location = location;
    notifyListeners();
  }

  set website(String website) {
    if (_website == website) return;
    _website = website;
    notifyListeners();
  }

  set bio(String bio) {
    if (_bio == bio) return;
    _bio = bio;
    notifyListeners();
  }

  set twitter(String twitter) {
    if (_twitter == twitter) return;
    _twitter = twitter;
    notifyListeners();
  }

  set instagram(String instagram) {
    if (_instagram == instagram) return;
    _instagram = instagram;
    notifyListeners();
  }

  set dribbble(String dribbble) {
    if (_dribbble == dribbble) return;
    _dribbble = dribbble;
    notifyListeners();
  }

  set linkedin(String linkedin) {
    if (_linkedin == linkedin) return;
    _linkedin = linkedin;
    notifyListeners();
  }

  set behance(String behance) {
    if (_behance == behance) return;
    _behance = behance;
    notifyListeners();
  }

  set vimeo(String vimeo) {
    if (_vimeo == vimeo) return;
    _vimeo = vimeo;
    notifyListeners();
  }

  set github(String github) {
    if (_github == github) return;
    _github = github;
    notifyListeners();
  }

  set medium(String medium) {
    if (_medium == medium) return;
    _medium = medium;
    notifyListeners();
  }

  bool get isEmailValid {
    if (isTeam) return true;
    // ignore: lines_longer_than_80_chars
    if (_email == null || _email == '') {
      emailValidationError = 'Missing email';
      return false;
    }
    if (!_emailRegEx.hasMatch(_email)) {
      emailValidationError = 'Email invalid';
      return false;
    }
    emailValidationError = null;
    return true;
  }

  bool get isNameValid {
    // ignore: lines_longer_than_80_chars
    if (_name == null || _name == '') {
      nameValidationError = 'Missing name';
      return false;
    }
    if (_name.length < 3) {
      nameValidationError = 'Name too short';
      return false;
    }
    nameValidationError = null;
    return true;
  }

  bool get isUsernameValid {
    // ignore: lines_longer_than_80_chars
    if (_username == null || _username == '') {
      usernameValidationError = 'Missing username';
      return false;
    }
    if (_username.length < 3) {
      usernameValidationError = 'Username too short';
      return false;
    }
    usernameValidationError = null;
    return true;
  }

  bool get isValid {
    var success = isEmailValid;
    success = isNameValid && success;
    success = isUsernameValid && success;
    notifyListeners();
    return success;
  }

  Profile profile() => Profile(
        name: name,
        username: username,
        email: email,
        website: website,
        bio: bio,
        location: location,
        twitter: twitter,
        instagram: instagram,
        linkedin: linkedin,
        medium: medium,
        github: github,
        behance: behance,
        vimeo: vimeo,
        dribbble: dribbble,
        isForHire: isForHire,
      );
}

class ProfileSettingsInner extends StatefulWidget {
  final Profile profile;
  final Owner owner;

  const ProfileSettingsInner({Key key, this.profile, this.owner})
      : super(key: key);
  @override
  State<StatefulWidget> createState() => _ProfileSettingsInnerState();
}

class _ProfileSettingsInnerState extends State<ProfileSettingsInner> {
  // User info.
  OwnerPackage package;

  @override
  void initState() {
    super.initState();
    package = OwnerPackage(
      name: widget.profile.name,
      username: widget.profile.username,
      email: widget.profile.email,
      location: widget.profile.location,
      website: widget.profile.website,
      bio: widget.profile.bio,
      twitter: widget.profile.twitter,
      instagram: widget.profile.instagram,
      dribbble: widget.profile.dribbble,
      linkedin: widget.profile.linkedin,
      behance: widget.profile.behance,
      vimeo: widget.profile.vimeo,
      github: widget.profile.github,
      medium: widget.profile.medium,
      isForHire: widget.profile.isForHire,
      isTeam: widget.owner is Team,
    );
    // Magic.
    package.addListener(() => setState(() {}));
  }

  Future<void> _submitChanges() async {
    if (package.processing) return;
    package.processing = true;

    try {
      if (!package.isValid) {
        return;
      }
      await ProfileManager().updateProfile(widget.owner, package.profile());
      if (widget.owner is Team) {
        await TeamManager().loadTeams();
      } else {
        await UserManager().loadMe();
      }

      // Close the popup
      Navigator.of(context).pop();
    } finally {
      package.processing = false;
    }
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

  Widget _list(List<Widget> children) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;

    return Column(
      // Stretches the separators
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
            child: ListView(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(30),
          children: children,
        )),
        Separator(color: colors.fileLineGrey),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: package.processing
                  ? const Center(child: CircularProgressIndicator())
                  : FlatIconButton(
                      label: 'Save Changes',
                      color: colors.commonDarkGrey,
                      textColor: Colors.white,
                      onTap: _submitChanges,
                    ),
            )
          ],
        )
      ],
    );
  }

  Widget _names() {
    var labelPrefix = widget.owner is Team ? 'Team ' : '';
    return _textFieldRow(
      [
        LabeledTextField(
          label: '${labelPrefix}Name',
          onChanged: (name) => package.name = name,
          initialValue: package.name,
          hintText: 'Pick a name',
          enabled: !package.processing,
          errorText: package.nameValidationError,
        ),
        LabeledTextField(
          label: '${labelPrefix}Username',
          onChanged: (username) => package.username = username,
          initialValue: package.username,
          hintText: 'Pick a username',
          enabled: !package.processing,
          errorText: package.usernameValidationError,
        ),
      ],
    );
  }

  List<Widget> _info() {
    if (widget.owner is Team) {
      return [
        const SizedBox(height: 3),
        _names(),
        SizedBox(
            height: (package.nameValidationError == null &&
                    package.usernameValidationError == null)
                ? 30
                : 10),
        _textFieldRow(
          [
            LabeledTextField(
              label: 'Location',
              hintText: 'Where is your team based?',
              onChanged: (location) => package.location = location,
              initialValue: package.location,
              enabled: !package.processing,
            ),
            LabeledTextField(
              label: 'Website',
              hintText: 'www.myteam.com',
              onChanged: (website) => package.website = website,
              initialValue: package.website,
              enabled: !package.processing,
            ),
          ],
        ),
        const SizedBox(height: 30),
        _textFieldRow(
          [
            LabeledTextField(
              label: 'Bio',
              hintText: 'Tell users a bit about your team',
              onChanged: (bio) => package.bio = bio,
              initialValue: package.bio,
              maxCharacters: 160,
              enabled: !package.processing,
            ),
          ],
        ),
      ];
    } else {
      return [
        const SizedBox(height: 3),
        _names(),
        SizedBox(
            height: (package.nameValidationError == null &&
                    package.usernameValidationError == null)
                ? 30
                : 10),
        _textFieldRow(
          [
            LabeledTextField(
              label: 'Email',
              hintText: 'Enter your email',
              onChanged: (email) => package.email = email,
              initialValue: package.email,
              enabled: !package.processing,
              errorText: package.emailValidationError,
            ),
            LabeledTextField(
              label: 'Website',
              hintText: 'www.mysite.com',
              onChanged: (website) => package.website = website,
              initialValue: package.website,
              enabled: !package.processing,
            ),
          ],
        ),
        SizedBox(height: (package.emailValidationError == null) ? 30 : 10),
        _textFieldRow(
          [
            LabeledTextField(
              label: 'Location',
              hintText: 'Where do you live?',
              onChanged: (location) => package.location = location,
              initialValue: package.location,
              enabled: !package.processing,
            ),
            const SizedBox(),
          ],
        ),
        const SizedBox(height: 30),
        _textFieldRow(
          [
            LabeledTextField(
              label: 'Bio',
              hintText: 'Tell users a bit about yourself...',
              onChanged: (bio) => package.bio = bio,
              initialValue: package.bio,
              maxCharacters: 160,
              enabled: !package.processing,
            ),
          ],
        ),
      ];
    }
  }

  List<Widget> get _forHire {
    return [
      DescriptionRadio(
        label: 'Available For Hire',
        description: 'Allow other users to message you about work'
            ' opportunities. You will also show up in our'
            ' list of artists for hire.',
        groupValue: package.isForHire,
        value: true,
        onChanged: (isForHire) => package.isForHire = isForHire,
      ),
      const SizedBox(height: 24),
      DescriptionRadio(
        label: 'Not Available For Hire',
        description: "Don't allow other users to contact you about"
            ' work opportunities.',
        groupValue: package.isForHire,
        value: false,
        onChanged: (isForHire) => package.isForHire = isForHire,
      ),
    ];
  }

  List<Widget> _socials() {
    return [
      const SizedBox(height: 3),
      _textFieldRow(
        [
          LabeledTextField(
            label: 'Twitter',
            hintText: 'Link',
            onChanged: (twitter) => package.twitter = twitter,
            initialValue: package.twitter,
            enabled: !package.processing,
          ),
          LabeledTextField(
            label: 'Instagram',
            hintText: 'Link',
            onChanged: (instagram) => package.instagram = instagram,
            initialValue: package.instagram,
            enabled: !package.processing,
          )
        ],
      ),
      const SizedBox(height: 30),
      _textFieldRow(
        [
          LabeledTextField(
            label: 'Dribbble',
            hintText: 'Link',
            onChanged: (dribbble) => package.dribbble = dribbble,
            initialValue: package.dribbble,
            enabled: !package.processing,
          ),
          LabeledTextField(
            label: 'LinkedIn',
            hintText: 'Link',
            onChanged: (linkedin) => package.linkedin = linkedin,
            initialValue: package.linkedin,
            enabled: !package.processing,
          )
        ],
      ),
      const SizedBox(height: 30),
      _textFieldRow(
        [
          LabeledTextField(
            label: 'Behance',
            hintText: 'Link',
            onChanged: (behance) => package.behance = behance,
            initialValue: package.behance,
            enabled: !package.processing,
          ),
          LabeledTextField(
            label: 'Vimeo',
            hintText: 'Link',
            onChanged: (vimeo) => package.vimeo = vimeo,
            initialValue: package.vimeo,
            enabled: !package.processing,
          )
        ],
      ),
      const SizedBox(height: 30),
      _textFieldRow(
        [
          LabeledTextField(
            label: 'GitHub',
            hintText: 'Link',
            onChanged: (github) => package.github = github,
            initialValue: package.github,
            enabled: !package.processing,
          ),
          LabeledTextField(
            label: 'Medium',
            hintText: 'Link',
            onChanged: (medium) => package.medium = medium,
            initialValue: package.medium,
            enabled: !package.processing,
          )
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    return _list(
      [
        SettingsPanelSection(
          label: 'Account',
          contents: (panelContext) => Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _info(),
          ),
        ),
        /* const SizedBox(height: 30),
        Separator(color: colors.fileLineGrey),
        const SizedBox(height: 30),
        SettingsPanelSection(
          label: 'For Hire',
          contents: (panelContext) => Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _forHire,
          ),
        ),*/
        const SizedBox(height: 30),
        Separator(color: colors.fileLineGrey),
        const SizedBox(height: 30),
        SettingsPanelSection(
          label: 'Social',
          contents: (panelContext) => Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: _socials(),
          ),
        ),
      ],
    );
  }
  // User info.

}

class DescriptionRadio extends StatelessWidget {
  final String label;
  final String description;
  final bool groupValue;
  final bool value;
  final ValueChanged<bool> onChanged;

  const DescriptionRadio({
    @required this.label,
    @required this.groupValue,
    @required this.onChanged,
    this.description,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (value != groupValue) onChanged(value);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
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
          Padding(
            // Padding: 20 (radio button) + 10 text padding
            padding: const EdgeInsets.only(left: 30.0),
            // TODO: add link to the "artists for hire".
            // What will it link to?
            child: Text(description,
                style: styles.hierarchyTabHovered
                    .copyWith(fontSize: 13, height: 1.6)),
          )
        ],
      ),
    );
  }
}
