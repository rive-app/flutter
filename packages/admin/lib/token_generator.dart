import 'package:admin/manager.dart';
import 'package:flutter/material.dart';

class TokenGenerator extends StatefulWidget {
  @override
  _TokenGeneratorState createState() => _TokenGeneratorState();
}

class _TokenGeneratorState extends State<TokenGenerator> {
  bool _processing = false;
  final _validEmails = <String>{};
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _multipleEmailValidator = RegExp(
      r"""(?:[a-z0-9!#$%&\'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&\'*+/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])""");

  void _showSnackBar(BuildContext context, String message) =>
      Scaffold.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 750),
        ),
      );

  void _validateEmailAddresses() {
    final emails =
        _multipleEmailValidator.allMatches(_email.text.toLowerCase());
    setState(() {
      emails.forEach((element) {
        final email = element.group(0); // First group contains the full match
        _validEmails.add(email);
      });
    });
  }

  Widget _emailInvite(String email) {
    return InputChip(
      label: Text(email),
      visualDensity: VisualDensity.comfortable,
      deleteButtonTooltipMessage: 'Remove',
      onDeleted: () {
        setState(() {
          _validEmails.remove(email);
        });
      },
    );
  }

  Widget _outbox() {
    if (_validEmails.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Send invites to:'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 5,
          children: _validEmails.map(_emailInvite).toList(growable: false),
        ),
        const SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invite someone via email.\n'
                'An email will be sent to the email address input below '
                'with a link to sign-up'),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Email'),
              controller: _email,
            ),
            const SizedBox(height: 10),
            Text('Inviting to: ${AdminManager.instance.api.host}'),
            const SizedBox(height: 20),
            RaisedButton(
              child: const Text('Validate Emails'),
              onPressed: _validateEmailAddresses,
            ),
            const SizedBox(height: 15),
            _outbox(),
            if (_validEmails.isNotEmpty)
              RaisedButton(
                child: const Text('Send'),
                onPressed: _processing
                    ? null
                    : () async {
                        _showSnackBar(context, 'Processing...');
                        setState(() {
                          _processing = true;
                        });
                        final inviteQueue = _validEmails.toList();
                        while (inviteQueue.isNotEmpty) {
                          final email = inviteQueue.removeLast();
                          _showSnackBar(context, 'Inviting $email');
                          final success =
                              await AdminManager.instance.invite(email);
                          if (!success) {
                            _showSnackBar(context,
                                'Failed to invite $email. Please try again');
                          } else {
                            setState(() {
                              _validEmails.remove(email);
                            });
                            _showSnackBar(context, 'Invite sent to $email!');
                          }
                        }

                        setState(() {
                          _processing = false;
                        });
                      },
              )
          ],
        ),
      ),
    );
  }
}
