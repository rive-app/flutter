import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/labeled_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class TeamAccount extends StatelessWidget {
  final Team team;

  const TeamAccount({Key key, this.team}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    // final colors = theme.colors;
    return ListView(
      padding: const EdgeInsets.all(30),
      physics: const ClampingScrollPhysics(),
      children: [
        Text(
          'Account',
          style: styles.greyText.copyWith(fontSize: 16),
        ),
        const SizedBox(height: 30),
        Text(
          'If you wish to delete your team, enter your password below and hit "Delete".',
          style: styles.greyText,
        ),
        const SizedBox(height: 30),
        Expanded(child: DeleteForm(team: team)),
      ],
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
  String errorText;
  void setError(String error) {
    setState(() {
      errorText = error;
    });
  }

  void clearError() {
    setState(() {
      errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    final theme = RiveTheme.of(context);
    // final styles = theme.textStyles;
    final colors = theme.colors;
    return Column(
      children: [
        Form(
            key: _form,
            child: Row(children: [
              Expanded(
                child: LabeledTextField(
                  obscureText: true,
                  controller: _confirmPass,
                  label: 'Confirm Password',
                  hintText: 'confirm your password to delete',
                  errorText: errorText,
                ),
              ),
              FlatIconButton(
                label: 'Delete',
                color: colors.accentMagenta,
                textColor: Colors.white,
                onTap: () {
                  // disable
                  TeamManager()
                      .delete(widget.team, _confirmPass.text)
                      .then((value) => Navigator.of(context).pop())
                      .catchError((dynamic error) {
                    if (error is ApiException) {
                      setError(error.error.message ?? 'Unknown Error.');
                    } else {
                      setError('Unknown Error.');
                    }
                  });
                  //

                  // set error.
                  // set goodbye.
                },
              )
            ])),
      ],
    );
  }
}
