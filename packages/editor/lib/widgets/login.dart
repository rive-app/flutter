import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/auth.dart';
import 'package:rive_editor/widgets/common/editor_switch.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/labeled_text_field.dart';
import 'package:rive_editor/widgets/common/underline_text_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:window_utils/window_utils.dart' as win_utils;

enum LoginPage { login, register, recover }
typedef AuthAction = Future<AuthResponse> Function();

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
  FormValidator loginValidator, registerValidator;

  bool _buttonDisabled = false;
  bool _isSending = false;
  LoginPage _currentPanel = LoginPage.login;
  String _usernameError, _emailError, _passwordError;

  @override
  void initState() {
    // Register validators for the various fields.
    final usernameValidator = NameValidator(onFieldError: (errorString) {
      setState(() {
        _usernameError = errorString;
      });
    });
    final emailValidator = EmailValidator(onFieldError: (errorString) {
      setState(() {
        _emailError = errorString;
      });
    });
    final passwordValidator = PasswordValidator(onFieldError: (errorString) {
      setState(() {
        _passwordError = errorString;
      });
    });
    final errorValidator = ErrorValidator(onFieldError: (errorString) {
      setState(() {
        _passwordError = errorString;
      });
    });
    loginValidator = FormValidator([errorValidator]);
    registerValidator = FormValidator([
      usernameValidator,
      emailValidator,
      passwordValidator,
    ]);
    super.initState();
  }

  void _selectPanel(LoginPage page) {
    if (page != _currentPanel) {
      setState(() {
        _currentPanel = page;
        // Reset error fields.
        _passwordError = null;
        _emailError = null;
        _usernameError = null;
      });
    }
  }

  // Process for password recovery.
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
      _selectPanel(LoginPage.login); // Back to login page.
    }
    setState(() {
      _isSending = false;
    });
  }

  // Try to sign up with the given credentials.
  Future<void> _signup() async {
    if (_buttonDisabled) {
      return;
    }

    final username = usernameController.text;
    final email = emailController.text;
    final password = passwordController.text;
    var emptyUsername = username.isEmpty;
    var emptyEmail = email.isEmpty;
    var emptyPassword = password.isEmpty;
    setState(() {
      _usernameError = emptyUsername ? 'Please fill this in.' : null;
      _passwordError = emptyPassword ? 'Please fill this in' : null;
      _emailError = emptyEmail ? 'Please fill this in' : null;
    });

    if (emptyEmail || emptyUsername || emptyPassword) {
      return;
    }

    _disableButton(true);
    final rive = RiveContext.of(context);
    final auth = RiveAuth(rive.api);

    var response = await auth.register(username, email, password);
    registerValidator.validate(response);

    if (response.isMessage) {
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

    var auth = RiveAuth(rive.api);
    final username = usernameController.text;
    final password = passwordController.text;

    var emptyUsername = username.isEmpty;
    var emptyPassword = password.isEmpty;
    setState(() {
      _usernameError = emptyUsername ? 'Please fill this in.' : null;
      _passwordError = emptyPassword ? 'Please fill this in' : null;
    });
    if (emptyUsername || emptyPassword) {
      return;
    }

    _disableButton(true);
    var response = await auth.login(username, password);
    loginValidator.validate(response);
    if (response.isMessage) {
      // Everything ok, we logged in.
      await rive.updateUser();
    } else {
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
                      ..onTap = () => _selectPanel(LoginPage.login),
                  ),
                ]),
          ),
          const SizedBox(height: 50),
          SizedBox(
            width: 216,
            child: LabeledTextField(
              label: 'Email or Username',
              hintText: 'Type your email or username…',
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
              elevation: flatButtonIconElevation,
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
                hintText: 'Pick a username',
                controller: usernameController,
                onSubmit: (_) => _signup(),
                errorText: _usernameError,
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: LabeledTextField(
                label: 'Email',
                hintText: 'you@domain.com',
                controller: emailController,
                onSubmit: (_) => _signup(),
                errorText: _emailError,
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
                hintText: '6 character minumum…',
                controller: passwordController,
                onSubmit: (_) => _signup(),
                errorText: _passwordError,
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
                ? colors.buttonDarkDisabled
                : colors.textButtonDark,
            textColor:
                _buttonDisabled ? colors.buttonDarkDisabledText : Colors.white,
            hoverColor: _buttonDisabled
                ? colors.buttonDarkDisabled
                : colors.textButtonDark,
            hoverTextColor: Colors.white,
            radius: 20,
            elevation: flatButtonIconElevation,
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ),
      ],
    );
  }

  void _disableButton(bool val) {
    if (val != _buttonDisabled) {
      setState(() {
        _buttonDisabled = val;
      });
    }
  }

  Future<void> _socialAuth(AuthAction auth) async {
    if (_buttonDisabled) {
      return;
    }
    _disableButton(true);
    final rive = RiveContext.of(context);
    final authResponse = await auth();
    if (authResponse.isMessage) {
      await rive.updateUser();
    } else {
      _disableButton(false);
    }
  }

  Widget _socials() {
    final isRegister = _currentPanel == LoginPage.register;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        /* TODO: not supported yet.
        _SocialSigninButton(
          label: 'Apple',
          icon: 'signin-apple',
          onTap: null, 
           _buttonDisabled
              ? null
              : () async {
                  final rive = RiveContext.of(context);
                  final api = rive.api;
                  final auth = RiveAuth(api);
                  _socialAuth(auth.loginApple); 
                },
        ),
        const SizedBox(width: 10),*/
        _SocialSigninButton(
          label: 'Google',
          icon: 'signin-google',
          onTap: _buttonDisabled
              ? null
              : () async {
                  final api = RiveContext.of(context).api;
                  final auth = RiveAuth(api);
                  await _socialAuth(
                      isRegister ? auth.registerGoogle : auth.loginGoogle);
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
                  await _socialAuth(
                      isRegister ? auth.registerFacebook : auth.loginFacebook);
                },
        ),
        /*
        const SizedBox(width: 10),
        _SocialSigninButton(
          label: 'Twitter',
          icon: 'signin-twitter',
          onTap: _buttonDisabled
              ? null
              : () async {
                  Scaffold.of(context).showSnackBar(const SnackBar(
                    content: Text("Coming soon!"),
                  ));
                  // final api = RiveContext.of(context).api;
                  // final auth = RiveAuth(api);
                  // await _socialAuth(
                  //     isRegister ? auth.registerTwitter : auth.loginTwitter);
                },
        ), */
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
                hintText: 'Type your email or username…',
                enabled: !_buttonDisabled,
                controller: usernameController,
                onSubmit: (_) => _login(),
                errorText: _usernameError,
              ),
            ),
            const SizedBox(width: 30),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LabeledTextField(
                    label: 'Password',
                    hintText: '6 character minumum…',
                    enabled: !_buttonDisabled,
                    controller: passwordController,
                    onSubmit: (_) => _login(),
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: 8),
                  UnderlineTextButton(
                    text: 'Forgot your Password?',
                    onPressed: () => _selectPanel(LoginPage.recover),
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
                ? colors.buttonDarkDisabled
                : colors.textButtonDark,
            textColor:
                _buttonDisabled ? colors.buttonDarkDisabledText : Colors.white,
            hoverColor: _buttonDisabled
                ? colors.buttonDarkDisabled
                : colors.textButtonDark,
            hoverTextColor: Colors.white,
            radius: 20,
            elevation: flatButtonIconElevation,
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ),
      ],
    );
  }

  Widget _panelContents() {
    return SizedBox(
        width: 473,
        height: 618,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top padding.
            const SizedBox(height: 160),
            Image.asset('assets/images/icons/rive-logo-login.png'),
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
    final colors = theme.colors;

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: GestureDetector(
            onTapDown: (_) {
              win_utils.startDrag();
            },
          ),
        ),
        Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            child: Container(
              color: colors.commonLightGrey,
              child: Image.asset(
                'assets/images/mother_of_dashes.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
              width: 714,
              child: Stack(children: [
                Positioned(
                    right: 30,
                    top: 30,
                    child: _LoginSwitch(
                        panel: _currentPanel, onSelect: _selectPanel)),
                Align(alignment: Alignment.center, child: _panelContents()),
              ])),
        ]),
      ],
    );
  }
}

class _LoginSwitch extends StatelessWidget {
  final LoginPage panel;
  final ValueChanged<LoginPage> onSelect;

  const _LoginSwitch({@required this.panel, @required this.onSelect, Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    final textStyles = theme.textStyles;
    final colors = theme.colors;

    bool isLogin;
    switch (panel) {
      case LoginPage.register:
        isLogin = true;
        break;
      case LoginPage.recover:
        isLogin = null;
        break;
      case LoginPage.login:
      default:
        isLogin = false;
        break;
    }

    return Container(
      height: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            onTap: () => onSelect(LoginPage.login),
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Text(
                'Log In',
                style: textStyles.regularText.copyWith(
                    color: panel == LoginPage.login
                        ? colors.commonDarkGrey
                        : colors.commonLightGrey),
              ),
            ),
          ),
          const SizedBox(width: 10),
          EditorSwitch(
            isOn: isLogin,
            toggle: () => onSelect(panel == LoginPage.register
                ? LoginPage.login
                : LoginPage.register),
            onColor: Colors.white,
            offColor: Colors.white,
            backgroundColor: panel == LoginPage.recover
                ? colors.toggleInactiveBackground
                : colors.toggleBackground,
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => onSelect(LoginPage.register),
            behavior: HitTestBehavior.opaque,
            child: Center(
              child: Text('Sign Up',
                  style: textStyles.regularText.copyWith(
                      color: panel == LoginPage.register
                          ? colors.commonDarkGrey
                          : colors.commonLightGrey)),
            ),
          ),
        ],
      ),
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
    var isEnabled = onTap != null;
    var buttonColor =
        isEnabled ? colors.buttonLight : colors.buttonLightDisabled;
    var textColor =
        isEnabled ? colors.buttonLightText : colors.buttonLightTextDisabled;
    var iconColor = isEnabled
        ? colors.iconButtonLightIcon
        : colors.iconButtonLightIconDisabled;
    return FlatIconButton(
        onTap: onTap,
        label: label,
        color: buttonColor,
        hoverColor: colors.buttonLightHover,
        hoverTextColor: colors.buttonLightText,
        textColor: textColor,
        icon: Padding(
          padding: const EdgeInsets.only(left: 25.0),
          child: TintedIcon(
            icon: icon,
            color: iconColor,
          ),
        ));
  }
}

class FormValidator {
  final List<FieldValidator> validators;
  const FormValidator(this.validators);

  void validate(AuthResponse response) {
    for (final val in validators) {
      val.validate(response);
    }
  }
}

abstract class FieldValidator {
  final ValueChanged<String> onFieldError;
  const FieldValidator({@required this.onFieldError});

  String get errorField;
  void validate(AuthResponse response);
}

class NameValidator extends FieldValidator {
  const NameValidator({@required ValueChanged<String> onFieldError})
      : super(onFieldError: onFieldError);

  @override
  String get errorField => 'username';

  @override
  void validate(AuthResponse response) {
    if (response == null) {
      return onFieldError('Not ready, cannot validate');
    }

    var errors = response.errors;
    if (response.isError && errors.containsKey(errorField)) {
      var error = errors[errorField];
      switch (error) {
        case 'in-use':
          return onFieldError('Not available');
        case 'too-short':
          return onFieldError('Too short.');
        case 'bad-characters':
          return onFieldError('Only alphanumeric and . or - are allowed.');
        default:
          return onFieldError('Unknown error, please try again later.');
      }
    }

    // Valid.
    return onFieldError(null);
  }
}

class PasswordValidator extends FieldValidator {
  const PasswordValidator({@required ValueChanged<String> onFieldError})
      : super(onFieldError: onFieldError);

  @override
  String get errorField => 'password';

  @override
  void validate(AuthResponse response) {
    if (response == null) {
      return onFieldError('Not ready, cannot validate');
    }

    var errors = response.errors;
    if (response.isError && errors.containsKey(errorField)) {
      var error = errors[errorField];
      switch (error) {
        case 'invalid':
          return onFieldError('Must be at least 3 characters long.');
        case 'too-short':
          return onFieldError('Too short.');
        default:
          return onFieldError('Unknown error, please try again later.');
      }
    }

    // Valid.
    return onFieldError(null);
  }
}

class EmailValidator extends FieldValidator {
  const EmailValidator({@required ValueChanged<String> onFieldError})
      : super(onFieldError: onFieldError);

  @override
  String get errorField => 'email';

  @override
  void validate(AuthResponse response) {
    if (response == null) {
      return onFieldError('Not ready, cannot validate');
    }

    var errors = response.errors;
    if (response.isError && errors.containsKey(errorField)) {
      var error = errors[errorField];
      switch (error) {
        case 'invalid':
          return onFieldError('Not a valid email');
        case 'in-use':
          return onFieldError('Aready registered');
        case 'missing':
          return onFieldError('Please fill this in!');
        default:
          return onFieldError('Unknown error, please try again later.');
      }
    }

    // Valid.
    return onFieldError(null);
  }
}

class ErrorValidator extends FieldValidator {
  const ErrorValidator({@required ValueChanged<String> onFieldError})
      : super(onFieldError: onFieldError);

  @override
  String get errorField => 'error';

  @override
  void validate(AuthResponse response) {
    if (response == null) {
      return onFieldError('Not ready, cannot validate');
    }

    var errors = response.errors;
    if (response.isError && errors.containsKey(errorField)) {
      var error = errors[errorField];
      return onFieldError(error);
    }

    // Valid.
    return onFieldError(null);
  }
}
