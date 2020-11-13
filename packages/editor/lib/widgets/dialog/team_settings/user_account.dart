import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_editor/external_url.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/labeled_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

const contactRive = 'mailto:info@rive.app?Subject=Rive%20Contact';

class UserAccount extends StatelessWidget {
  const UserAccount({Key key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final styles = theme.textStyles;
    // final colors = theme.colors;
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm your password to delete your account. You won’t be '
              'able to access any files or teams after deleting your account. '
              'The account will remain recoverable for 90 days.',
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
            Expanded(child: DeleteForm()),
          ],
        ),
      ),
    );
  }
}

class DeleteForm extends StatefulWidget {
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
    return Form(
      key: _form,
      child: Column(
        children: [
          Row(children: [
            Expanded(
              child: LabeledTextField(
                obscureText: true,
                controller: _confirmPass,
                label: 'Confirm Password',
                hintText: 'confirm your password to delete',
                errorText: errorText,
              ),
            ),
            const SizedBox(width: 30),
            const Expanded(child: SizedBox())
          ]),
          const SizedBox(height: 30),
          Row(children: [
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
                label: 'Delete',
                color: colors.accentMagenta,
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                textColor: Colors.white,
                onTap: () {
                  // disable
                  UserManager()
                      .delete(_confirmPass.text)
                      .then((value) => Navigator.of(context).pop())
                      .catchError((dynamic error) {
                    if (error is ApiException) {
                      setError(error.error.message ?? 'Unknown Error.');
                    } else {
                      setError('Unknown Error.');
                    }
                  });
                },
              ),
            )
          ]),
        ],
      ),
    );
  }
}
