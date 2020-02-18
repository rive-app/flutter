import 'package:flutter/material.dart';
import 'package:rive_api/auth.dart';
import 'package:rive_editor/rive/rive.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:window_utils/window_utils.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class ObscuringTextEditingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({TextStyle style, bool withComposing}) {
    var displayValue = '•' * value.text.length;
    if (!value.composing.isValid || !withComposing) {
      return TextSpan(style: style, text: displayValue);
    }
    final TextStyle composingStyle = style.merge(
      const TextStyle(decoration: TextDecoration.underline),
    );
    return TextSpan(
      style: style,
      children: <TextSpan>[
        TextSpan(text: value.composing.textBefore(displayValue)),
        TextSpan(
          style: composingStyle,
          text: value.composing.textInside(displayValue),
        ),
        TextSpan(text: value.composing.textAfter(displayValue)),
      ],
    );
  }
}

class _LoginState extends State<Login> {
  final passwordController = ObscuringTextEditingController();
  final usernameController = TextEditingController();
  String username;
  bool _isLoggingIn = false;
  @override
  Widget build(BuildContext context) {
    var rive = RiveContext.of(context);
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            onTapDown: (_) {
              WindowUtils.startDrag();
            },
          ),
        ),
        Positioned.fill(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(minWidth: 100, maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    enabled: !_isLoggingIn,
                    controller: usernameController,
                    decoration: const InputDecoration(hintText: 'Username'),
                    onSubmitted: (_) => _submit(rive),
                  ),
                  TextField(
                    enabled: !_isLoggingIn,
                    controller: passwordController,
                    decoration: const InputDecoration(hintText: 'Password'),
                    onSubmitted: (_) => _submit(rive),
                  ),
                  FlatButton(
                    child: Text(_isLoggingIn ? 'Verifying' : 'Login'),
                    onPressed: _isLoggingIn ? null : () => _submit(rive),
                  ),
                  FlatButton(
                    child: const Text('Login with Twitter'),
                    onPressed: _isLoggingIn
                        ? null
                        : () async {
                            var auth = RiveAuth(rive.api);
                            if (await auth.loginTwitter()) {
                              await rive.updateUser();
                            }
                          },
                  ),
                  FlatButton(
                    child: const Text('Login with Facebook'),
                    onPressed: _isLoggingIn
                        ? null
                        : () async {
                            var auth = RiveAuth(rive.api);
                            if (await auth.loginFacebook()) {
                              await rive.updateUser();
                            }
                          },
                  ),
                  FlatButton(
                    child: const Text('Login with Google'),
                    onPressed: _isLoggingIn
                        ? null
                        : () async {
                            var auth = RiveAuth(rive.api);
                            if (await auth.loginGoogle()) {
                              await rive.updateUser();
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submit(Rive rive) async {
    setState(() {
      _isLoggingIn = true;
    });
    var auth = RiveAuth(rive.api);
    if (await auth.login(
      usernameController.text,
      passwordController.text,
    )) {
      await rive.updateUser();
    }
    setState(() {
      _isLoggingIn = false;
    });
  }
}
