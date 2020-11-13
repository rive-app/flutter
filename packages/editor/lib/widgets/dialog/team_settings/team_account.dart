import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_editor/external_url.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/labeled_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

const contactRive = 'mailto:info@rive.app?Subject=Rive%20Contact';

class TeamAccount extends StatelessWidget {
  final Team team;

  const TeamAccount({Key key, this.team}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    // final colors = theme.colors;
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 170,
            child: Text(
              'Are you sure you want to delete this team?',
              style: styles.greyText.copyWith(fontSize: 16),
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            child: Column(
              children: [
                Text(
                  'If you delete the team, you and all team members will no '
                  'longer be able to access the team or any of its files.',
                  style: styles.paragraphText,
                ),
                const SizedBox(height: 30),
                RichText(
                    text: TextSpan(
                  children: [
                    const TextSpan(text: 'Upon deleting the team, you can '),
                    TextSpan(
                      text: 'contact us',
                      style: styles.paragraphTextHyperlink,
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => launchUrl(contactRive),
                    ),
                    const TextSpan(
                      text: ' within 90 days to reverse the process and '
                          'recover your files. After 90 days, we will no '
                          'longer be able to restore the team or any of '
                          'the files associated with it.',
                    ),
                  ],
                  style: styles.paragraphText,
                )),
                const SizedBox(height: 30),
                Text(
                  'If you’re on an annual payment plan, we’ll refund you '
                  'any pre-paid balance after the 90 day recovery window.',
                  style: styles.paragraphText,
                ),
                const SizedBox(height: 30),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Drop us a note',
                        style: styles.paragraphTextHyperlink,
                        recognizer: TapGestureRecognizer()
                          ..onTap = () => launchUrl(contactRive),
                      ),
                      const TextSpan(
                        text: ' if you have any questions, we’re always '
                            'available to help.',
                      ),
                    ],
                    style: styles.paragraphText,
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(child: DeleteForm(team: team)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class DeleteForm extends StatefulWidget {
  final Team team;

  const DeleteForm({Key key, this.team}) : super(key: key);
  @override
  _DeleteFormState createState() => _DeleteFormState();
}

class _DeleteFormState extends State<DeleteForm> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _confirmPass = TextEditingController();
  final TextEditingController _confirmTeamName = TextEditingController();
  String passwordError;
  String teamNameError;

  bool enabled = false;
  bool validTeamName = false;

  void checkTeamName() {
    setState(() {
      validTeamName = _confirmTeamName.text == widget.team.name;
      enabled =
          _confirmTeamName.text.isNotEmpty && _confirmPass.text.isNotEmpty;
    });
  }

  void setPasswordError(String error) {
    setState(() {
      passwordError = error;
    });
  }

  void setTeamNameError(String error) {
    setState(() {
      teamNameError = error;
    });
  }

  void clearError() {
    setState(() {
      passwordError = null;
      teamNameError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    return Form(
      key: _form,
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(bottom: (passwordError == null) ? 0 : 20),
                child: LabeledTextField(
                  obscureText: true,
                  controller: _confirmTeamName,
                  label: 'Team name',
                  hintText: 'confirm the team name',
                  errorText: teamNameError,
                  onChanged: (_) => checkTeamName(),
                ),
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: Padding(
                padding:
                    EdgeInsets.only(bottom: (teamNameError == null) ? 0 : 20),
                child: LabeledTextField(
                  obscureText: true,
                  controller: _confirmPass,
                  label: 'Password',
                  hintText: 'confirm your password',
                  errorText: passwordError,
                  onChanged: (_) => checkTeamName(),
                ),
              ),
            ),
          ]),
          if (teamNameError == null && passwordError == null)
            const SizedBox(height: 20),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: FlatIconButton(
                  label: 'No, take me back',
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  onTap: Navigator.of(context).pop,
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: FlatIconButton(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  label: 'Yes, delete my team',
                  color: enabled ? colors.accentMagenta : null,
                  textColor: enabled ? Colors.white : colors.input,
                  onTap: () {
                    clearError();
                    if (!enabled) return;
                    if (!validTeamName) {
                      setTeamNameError('Incorrect Team Name.');
                      return;
                    }
                    // disable
                    TeamManager()
                        .delete(widget.team, _confirmPass.text)
                        .then((value) => Navigator.of(context).pop())
                        .catchError((dynamic error) {
                      if (error is ApiException) {
                        print(error);
                        setPasswordError(
                            error.error.message ?? 'Unknown Error.');
                      } else {
                        setPasswordError('Unknown Error.');
                      }
                    });
                  },
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
