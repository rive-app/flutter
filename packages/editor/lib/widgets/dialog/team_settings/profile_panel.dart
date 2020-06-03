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

class ProfileSettings extends StatefulWidget {
  final Owner owner;
  const ProfileSettings(this.owner);

  @override
  State<StatefulWidget> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  // User info.
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _websiteController = TextEditingController();
  final _bioController = TextEditingController();
  // Socials.
  final _twitterController = TextEditingController();
  final _instagramController = TextEditingController();
  final _dribbbleController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _behanceController = TextEditingController();
  final _vimeoController = TextEditingController();
  final _githubController = TextEditingController();
  final _mediumController = TextEditingController();

  bool _isForHire;

  StreamSubscription<Profile> _profileSubscription;

  @override
  void initState() {
    super.initState();
    final profileId = widget.owner.ownerId;
    _profileSubscription =
        Plumber().getStream<Profile>(profileId).listen(_onProfile);
    // TODO: check for errors
    ProfileManager().loadProfile(widget.owner);
  }

  void _onProfile(Profile profile) {
    assert(profile != null);
    setState(() {
      _isForHire = profile.isForHire == true;
    });
  }

  @override
  void dispose() {
    // Cleanup.
    _profileSubscription.cancel();

    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _bioController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _dribbbleController.dispose();
    _linkedinController.dispose();
    _behanceController.dispose();
    _vimeoController.dispose();
    _githubController.dispose();
    _mediumController.dispose();

    super.dispose();
  }

  Future<void> _submitChanges() async {
    final updatedProfile = Profile(
      name: _nameController.text,
      username: _usernameController.text,
      email: _emailController.text,
      avatar: widget.owner.avatarUrl,
      website: _websiteController.text,
      bio: _bioController.text,
      location: _locationController.text,
      twitter: _twitterController.text,
      instagram: _instagramController.text,
      linkedin: _linkedinController.text,
      medium: _mediumController.text,
      github: _githubController.text,
      behance: _behanceController.text,
      vimeo: _vimeoController.text,
      dribbble: _dribbbleController.text,
      isForHire: _isForHire,
    );
    await ProfileManager().updateProfile(widget.owner, updatedProfile);
    TeamManager().loadTeams();
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
              child: FlatIconButton(
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

  Widget _names(Profile profile) {
    var labelPrefix = widget.owner is Team ? 'Team ' : '';
    return _textFieldRow(
      [
        LabeledTextField(
          label: '${labelPrefix}Name',
          controller: _nameController,
          initialValue: profile.name,
          hintText: 'Pick a name',
        ),
        LabeledTextField(
          label: '${labelPrefix}Username',
          controller: _usernameController,
          initialValue: profile.username,
          hintText: 'Pick a username',
        )
      ],
    );
  }

  List<Widget> _info(Profile profile) {
    if (widget.owner is Team) {
      return [
        const SizedBox(height: 3),
        _names(profile),
        const SizedBox(height: 30),
        _textFieldRow(
          [
            LabeledTextField(
              label: 'Location',
              hintText: 'Where is your team based?',
              controller: _locationController,
              initialValue: profile.location,
            ),
            LabeledTextField(
              label: 'Website',
              hintText: 'www.myteam.com',
              controller: _websiteController,
              initialValue: profile.website,
            ),
          ],
        ),
        const SizedBox(height: 30),
        _textFieldRow(
          [
            LabeledTextField(
              label: 'Bio',
              hintText: 'Tell users a bit about your team',
              controller: _bioController,
              initialValue: profile.bio,
            ),
          ],
        ),
      ];
    } else {
      return [
        const SizedBox(height: 3),
        _names(profile),
        const SizedBox(height: 30),
        _textFieldRow(
          [
            LabeledTextField(
              label: 'Email',
              hintText: 'Enter your email',
              controller: _emailController,
              initialValue: profile.email,
            ),
            LabeledTextField(
              label: 'Website',
              hintText: 'www.mysite.com',
              controller: _websiteController,
              initialValue: profile.website,
            ),
          ],
        ),
        const SizedBox(height: 30),
        _textFieldRow(
          [
            LabeledTextField(
              label: 'Location',
              hintText: 'Where do you live?',
              controller: _locationController,
              initialValue: profile.location,
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
              controller: _bioController,
              initialValue: profile.bio,
            ),
          ],
        ),
      ];
    }
  }

  List<Widget> get _forHire {
    return [
      LabeledRadio(
        label: 'Available For Hire',
        description: 'Allow other users to message you about work'
            ' opportunities. You will also show up in our'
            ' list of artists for hire.',
        groupValue: _isForHire,
        value: true,
        onChanged: (value) {
          setState(() {
            _isForHire = value;
          });
        },
      ),
      const SizedBox(height: 24),
      LabeledRadio(
        label: 'Not Available For Hire',
        description: "Don't allow other users to contact you about"
            ' work opportunities.',
        groupValue: _isForHire,
        value: false,
        onChanged: (value) {
          setState(() {
            _isForHire = value;
          });
        },
      ),
    ];
  }

  List<Widget> _socials(Profile profile) {
    return [
      const SizedBox(height: 3),
      _textFieldRow(
        [
          LabeledTextField(
            label: 'Twitter',
            hintText: 'Link',
            controller: _twitterController,
            initialValue: profile.twitter,
          ),
          LabeledTextField(
            label: 'Instagram',
            hintText: 'Link',
            controller: _instagramController,
            initialValue: profile.instagram,
          )
        ],
      ),
      const SizedBox(height: 30),
      _textFieldRow(
        [
          LabeledTextField(
            label: 'Dribbble',
            hintText: 'Link',
            controller: _dribbbleController,
            initialValue: profile.dribbble,
          ),
          LabeledTextField(
            label: 'LinkedIn',
            hintText: 'Link',
            controller: _linkedinController,
            initialValue: profile.linkedin,
          )
        ],
      ),
      const SizedBox(height: 30),
      _textFieldRow(
        [
          LabeledTextField(
            label: 'Behance',
            hintText: 'Link',
            controller: _behanceController,
            initialValue: profile.behance,
          ),
          LabeledTextField(
            label: 'Vimeo',
            hintText: 'Link',
            controller: _vimeoController,
            initialValue: profile.vimeo,
          )
        ],
      ),
      const SizedBox(height: 30),
      _textFieldRow(
        [
          LabeledTextField(
            label: 'GitHub',
            hintText: 'Link',
            controller: _githubController,
            initialValue: profile.github,
          ),
          LabeledTextField(
            label: 'Medium',
            hintText: 'Link',
            controller: _mediumController,
            initialValue: profile.medium,
          )
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ValueStreamBuilder<Profile>(
      stream: Plumber().getStream<Profile>(widget.owner.ownerId),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final theme = RiveTheme.of(context);
          final colors = theme.colors;
          final profile = snapshot.data;

          return _list(
            [
              SettingsPanelSection(
                label: 'Account',
                contents: (panelContext) => Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _info(profile),
                ),
              ),
              const SizedBox(height: 30),
              Separator(color: colors.fileLineGrey),
              const SizedBox(height: 30),
              SettingsPanelSection(
                label: 'For Hire',
                contents: (panelContext) => Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _forHire,
                ),
              ),
              const SizedBox(height: 30),
              Separator(color: colors.fileLineGrey),
              const SizedBox(height: 30),
              SettingsPanelSection(
                label: 'Social',
                contents: (panelContext) => Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _socials(profile),
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class LabeledRadio extends StatelessWidget {
  final String label;
  final String description;
  final bool groupValue;
  final bool value;
  final ValueChanged<bool> onChanged;

  const LabeledRadio({
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
