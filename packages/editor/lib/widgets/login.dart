import 'package:flutter/material.dart';
import 'package:rive_api/auth.dart';
import 'package:rive_editor/widgets/common/editor_switch.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/underline_text_button.dart';
import 'package:rive_editor/widgets/dialog/team_settings/labeled_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
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
  final ObscuringTextEditingController passwordController =
      ObscuringTextEditingController();
  final TextEditingController usernameController = TextEditingController();
  String username;
  bool _isLoggingIn = false;
  bool _isLoginPanel = true;

  void _switchPanel() {
    setState(() {
      _isLoginPanel = !_isLoginPanel;
    });
  }

  Future<void> _submit() async {
    if (_isLoggingIn) {
      return;
    }

    final rive = RiveContext.of(context);

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
    if (mounted) {
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  Widget _loginForm() {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top padding.
        const SizedBox(height: 100),
        Image.asset('assets/images/rive_logo.png'),
        const SizedBox(height: 55),
        Text(
          'One-click sign in if your account is connected to',
          style: styles.loginText,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SocialSigninButton(
              label: 'Apple',
              icon: 'signin-apple',
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _SocialSigninButton(
              label: 'Google',
              icon: 'signin-google',
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _SocialSigninButton(
              label: 'Facebook',
              icon: 'signin-facebook',
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _SocialSigninButton(
              label: 'Twitter',
              icon: 'signin-twitter',
              onTap: () {},
            ),
          ],
        ),
        const SizedBox(height: 60),
        ConstrainedBox(
          // Would really like to find a better way to handle this.
          constraints: const BoxConstraints(
            maxWidth: 473,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Email or Username',
                  hint: 'Type your email or username…',
                  enabled: !_isLoggingIn,
                  controller: usernameController,
                  onSubmit: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LabeledTextField(
                      label: 'Password',
                      hint: '6 character minumum…',
                      enabled: !_isLoggingIn,
                      controller: passwordController,
                      onSubmit: (_) => _submit(),
                    ),
                    const SizedBox(height: 8),
                    UnderlineTextButton(
                      text: 'Forgot your Password?',
                      onPressed: () {/** TODO: */},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: 145,
          child: FlatIconButton(
            label: _isLoggingIn ? 'Verifying' : 'Log In',
            onTap: _submit,
            color: colors.commonDarkGrey,
            textColor: Colors.white,
            radius: 20,
            elevated: true,
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            onTapDown: (_) {
              WindowUtils.startDrag();
            },
          ),
        ),
        Row(children: [
          // TODO: image background or Rive animation.
          Flexible(
              child: Container(
            color: Colors.lime[100],
          )),
          SizedBox(
              width: 714,
              child: Stack(children: [
                Positioned(
                  right: 30,
                  top: 30,
                  child: EditorSwitch(
                    isOn: _isLoginPanel,
                    toggle: _switchPanel,
                    onColor: Colors.white,
                    offColor: Colors.white,
                  ),
                ),
                Align(alignment: Alignment.center, child: _loginForm()),
              ])),
        ]),
        // Positioned.fill(
        //   child: Center(
        //     child: Container(
        //       constraints: const BoxConstraints(minWidth: 100, maxWidth: 400),
        //       child: Column(
        //         mainAxisAlignment: MainAxisAlignment.center,
        //         children: [
        //           TextField(
        //             autofocus: true,
        //             enabled: !_isLoggingIn,
        //             controller: usernameController,
        //             decoration: const InputDecoration(hintText: 'Username'),
        //             onSubmitted: (_) => _submit(rive),
        //           ),
        //           TextField(
        //             enabled: !_isLoggingIn,
        //             controller: passwordController,
        //             decoration: const InputDecoration(hintText: 'Password'),
        //             onSubmitted: (_) => _submit(rive),
        //           ),
        //           Container(height: 20.0),
        //           RaisedButton(
        //             child: Text(_isLoggingIn ? 'Verifying' : 'Login'),
        //             onPressed: _isLoggingIn ? null : () => _submit(rive),
        //           ),
        //           FlatButton(
        //             child: const Text('Login with Twitter'),
        //             onPressed: _isLoggingIn
        //                 ? null
        //                 : () async {
        //                     var auth = RiveAuth(rive.api);
        //                     if (await auth.loginTwitter()) {
        //                       await rive.updateUser();
        //                     }
        //                   },
        //           ),
        //           FlatButton(
        //             child: const Text('Login with Facebook'),
        //             onPressed: _isLoggingIn
        //                 ? null
        //                 : () async {
        //                     var auth = RiveAuth(rive.api);
        //                     if (await auth.loginFacebook()) {
        //                       await rive.updateUser();
        //                     }
        //                   },
        //           ),
        //           FlatButton(
        //             child: const Text('Login with Google'),
        //             onPressed: _isLoggingIn
        //                 ? null
        //                 : () async {
        //                     var auth = RiveAuth(rive.api);
        //                     if (await auth.loginGoogle()) {
        //                       await rive.updateUser();
        //                     }
        //                   },
        //           ),
        //         ],
        //       ),
        //     ),
        //   ),
        // ),
      ],
    );
  }
}

class _SocialSigninButton extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const _SocialSigninButton(
      {@required this.label,
      @required this.icon,
      @required this.onTap,
      Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = RiveTheme.of(context).colors;
    return FlatIconButton(
        label: label,
        icon: Padding(
          padding: const EdgeInsets.only(left: 25.0),
          child: TintedIcon(
            icon: icon,
            color: colors.commonButtonTextColor,
          ),
        ));
  }
}
