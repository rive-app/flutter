import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/auth.dart';
import 'package:rive_editor/widgets/common/editor_switch.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/underline_text_button.dart';
import 'package:rive_editor/widgets/dialog/team_settings/labeled_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:window_utils/window_utils.dart';

enum LoginPage { login, register, recover }
typedef LoginFunction = Future<bool> Function();

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
  final TextEditingController emailController = TextEditingController();

  bool _buttonDisabled = false;
  bool _isSending = false;
  LoginPage _currentPanel = LoginPage.login;

  void _togglePanel() {
    setState(() {
      if (_currentPanel == LoginPage.login) {
        _currentPanel = LoginPage.register;
      } else {
        _currentPanel = LoginPage.login;
      }
    });
  }

  Future<void> _recover() async {
    if (_isSending) {
      return;
    }
    setState(() {
      _isSending = true;
    });
    final api = RiveContext.of(context).api;
    var auth = RiveAuth(api);
    final emailSent =
        await auth.forgot(Uri.encodeComponent(usernameController.text));
    if (emailSent) {
      // print("Sent recovery email!");
      _togglePanel(); // Back to login page.
    }
    setState(() {
      _isSending = false;
    });
  }

  Future<void> _signup() async {
    if (_buttonDisabled) {
      return;
    }
    _disableButton(true);

    final username = usernameController.text;
    final email = emailController.text;
    final password = passwordController.text;

    final rive = RiveContext.of(context);
    final auth = RiveAuth(rive.api);

    if (await auth.register(username, email, password)) {
      await rive.updateUser();
    } else {
      _disableButton(false);
    }
  }

  Future<void> _login() async {
    if (_buttonDisabled) {
      return;
    }

    final rive = RiveContext.of(context);

    _disableButton(true);
    var auth = RiveAuth(rive.api);
    if (await auth.login(
      usernameController.text,
      passwordController.text,
    )) {
      await rive.updateUser();
    }
    if (mounted) {
      _disableButton(false);
    }
  }

  Widget get _visibleForm {
    switch (_currentPanel) {
      case LoginPage.recover:
        return _recoverForm();
      case LoginPage.register:
        return _registerForm();
      case LoginPage.login:
      default:
        return _loginForm();
    }
  }

  Widget _recoverForm() {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;
    return Column(
        key: const ValueKey<int>(2),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
                style: styles.loginText.copyWith(height: 1.6),
                text: 'Forgot your password? Type in the email or username'
                    ' associated with your account and we’ll send you an'
                    ' email to reset it. ',
                children: [
                  TextSpan(
                    text: 'Back to sign in.',
                    style: styles.buttonUnderline
                        .copyWith(height: 1.6, fontSize: 13),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => setState(() {
                            _currentPanel = LoginPage.login;
                          }),
                  ),
                ]),
          ),
          const SizedBox(height: 50),
          SizedBox(
            width: 216,
            child: LabeledTextField(
              label: 'Email or Username',
              hint: 'Type your email or username…',
              controller: usernameController,
              onSubmit: (_) => _recover(),
            ),
          ),
          const SizedBox(height: 60),
          SizedBox(
            width: 145,
            child: FlatIconButton(
              label: 'Send Email',
              onTap: _recover,
              color:
                  _isSending ? colors.commonLightGrey : colors.commonDarkGrey,
              textColor: Colors.white,
              radius: 20,
              elevated: true,
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ),
        ]);
  }

  Widget _registerForm() {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;
    return Column(
        key: const ValueKey<int>(1),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect an account for one-click sign in',
            style: styles.loginText,
          ),
          const SizedBox(height: 20),
          _socials(),
          const SizedBox(height: 60),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Username',
                  hint: 'Pick a username',
                  controller: usernameController,
                  onSubmit: (_) => _signup(),
                ),
              ),
              const SizedBox(width: 30),
              Expanded(
                child: LabeledTextField(
                  label: 'Email',
                  hint: 'you@domain.com',
                  controller: emailController,
                  onSubmit: (_) => _signup(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Password',
                  hint: '6 character minumum…',
                  controller: passwordController,
                  onSubmit: (_) => _signup(),
                ),
              ),
              const SizedBox(width: 30),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 145,
            child: FlatIconButton(
              label: _buttonDisabled ? 'Verifying' : 'Sign Up',
              onTap: _signup,
              color: _buttonDisabled
                  ? colors.commonLightGrey
                  : colors.commonDarkGrey,
              textColor: Colors.white,
              radius: 20,
              elevated: true,
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ),
        ]);
  }

  void _disableButton(bool val) {
    if (val != _buttonDisabled) {
      setState(() {
        _buttonDisabled = val;
      });
    }
  }

  void _socialLogin(LoginFunction loginFunc) async {
    if (_buttonDisabled) {
      return;
    }
    _disableButton(true);
    final rive = RiveContext.of(context);

    if (await loginFunc()) {
      await rive.updateUser();
    } else {
      _disableButton(false);
    }
  }

  Widget _socials() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SocialSigninButton(
          label: 'Apple',
          icon: 'signin-apple',
          onTap: null, // TODO: not supported yet.
          /* _buttonDisabled
              ? null
              : () async {
                  final rive = RiveContext.of(context);
                  final api = rive.api;
                  final auth = RiveAuth(api);
                  _socialLogin(auth.loginApple); 
                },*/
        ),
        const SizedBox(width: 10),
        _SocialSigninButton(
          label: 'Google',
          icon: 'signin-google',
          onTap: _buttonDisabled
              ? null
              : () async {
                  final api = RiveContext.of(context).api;
                  final auth = RiveAuth(api);
                  _socialLogin(auth.loginGoogle);
                },
        ),
        const SizedBox(width: 10),
        _SocialSigninButton(
          label: 'Facebook',
          icon: 'signin-facebook',
          onTap: _buttonDisabled
              ? null
              : () async {
                  final api = RiveContext.of(context).api;
                  final auth = RiveAuth(api);
                  _socialLogin(auth.loginFacebook);
                },
        ),
        const SizedBox(width: 10),
        _SocialSigninButton(
          label: 'Twitter',
          icon: 'signin-twitter',
          onTap: _buttonDisabled
              ? null
              : () async {
                  final api = RiveContext.of(context).api;
                  final auth = RiveAuth(api);
                  _socialLogin(auth.loginTwitter);
                },
        ),
      ],
    );
  }

  Widget _loginForm() {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;
    return Column(
        key: const ValueKey<int>(0),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'One-click sign in if your account is connected to',
            style: styles.loginText,
          ),
          const SizedBox(height: 20),
          _socials(),
          const SizedBox(height: 60),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: LabeledTextField(
                  label: 'Email or Username',
                  hint: 'Type your email or username…',
                  enabled: !_buttonDisabled,
                  controller: usernameController,
                  onSubmit: (_) => _login(),
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
                      enabled: !_buttonDisabled,
                      controller: passwordController,
                      onSubmit: (_) => _login(),
                    ),
                    const SizedBox(height: 8),
                    UnderlineTextButton(
                      text: 'Forgot your Password?',
                      onPressed: () => setState(() {
                        _currentPanel = LoginPage.recover;
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: 145,
            child: FlatIconButton(
              label: _buttonDisabled ? 'Verifying' : 'Log In',
              onTap: _login,
              color: _buttonDisabled
                  ? colors.commonLightGrey
                  : colors.commonDarkGrey,
              textColor: Colors.white,
              radius: 20,
              elevated: true,
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ),
        ]);
  }

  Widget _panelContents() {
    return SizedBox(
        width: 473,
        height: 578,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top padding.
            const SizedBox(height: 160),
            Image.asset('assets/images/rive_logo.png'),
            const SizedBox(height: 55),
            AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                child: _visibleForm),
          ],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final colors = theme.colors;

    bool isSwitchOn;
    switch (_currentPanel) {
      case LoginPage.register:
        isSwitchOn = true;
        break;
      case LoginPage.recover:
        isSwitchOn = null;
        break;
      case LoginPage.login:
      default:
        isSwitchOn = false;
        break;
    }

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
            color: colors.commonLightGrey,
          )),
          SizedBox(
              width: 714,
              child: Stack(children: [
                Positioned(
                  right: 30,
                  top: 30,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Log In',
                        style: textStyles.regularText.copyWith(
                            color: _currentPanel == LoginPage.login
                                ? colors.commonDarkGrey
                                : colors.commonLightGrey),
                      ),
                      const SizedBox(width: 10),
                      EditorSwitch(
                        isOn: isSwitchOn,
                        toggle: _togglePanel,
                        onColor: Colors.white,
                        offColor: Colors.white,
                        backgroundColor: isSwitchOn == null
                            ? colors.toggleInactiveBackground
                            : colors.toggleBackground,
                      ),
                      const SizedBox(width: 10),
                      Text('Sign Up',
                          style: textStyles.regularText.copyWith(
                              color: _currentPanel == LoginPage.register
                                  ? colors.commonDarkGrey
                                  : colors.commonLightGrey)),
                    ],
                  ),
                ),
                Align(alignment: Alignment.center, child: _panelContents()),
              ])),
        ]),
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
        onTap: onTap,
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
