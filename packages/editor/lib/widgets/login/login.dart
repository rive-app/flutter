import 'package:pedantic/pedantic.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:rive_api/auth.dart';
import 'package:rive_api/manager.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/plumber.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/common/editor_switch.dart';
import 'package:rive_editor/widgets/common/flat_icon_button.dart';
import 'package:rive_editor/widgets/common/labeled_text_field.dart';
import 'package:rive_editor/widgets/common/underline_text_button.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/login/obscuring_controller.dart';
import 'package:rive_editor/widgets/login/validators.dart';
import 'package:rive_editor/widgets/theme.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';
import 'package:window_utils/window_utils.dart' as win_utils;

enum LoginPage { login, register, recover, link }
typedef AuthAction = Future<AuthResponse> Function();

class Login extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final ObscuringTextEditingController passwordController =
      ObscuringTextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  FormValidator loginValidator, registerValidator;

  bool _buttonDisabled = false;
  bool _isSending = false;
  LoginPage _currentPanel;
  String _usernameError, _emailError, _passwordError;

  @override
  void initState() {
    // When logging in or registering with a social account, the server
    // can redirect back to this page on error.
    UserManager().errorMessage.then((error) {
      // Display that error right if it is present, and display it under the
      // password error field as that is where we show errors in the
      // 'login' page.
      setState(() {
        _passwordError = error;
      });
    });

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
    final errorValidator = ErrorValidator(
        errorField: 'error',
        onFieldError: (errorString) {
          setState(() {
            _passwordError = errorString;
          });
        });

    final inviteValidator = ErrorValidator(
        errorField: 'invite',
        onFieldError: (errorString) {
          setState(() {
            _usernameError = errorString;
          });
        });

    loginValidator = FormValidator([errorValidator]);
    registerValidator = FormValidator([
      usernameValidator,
      emailValidator,
      passwordValidator,
      inviteValidator,
    ]);
    var currentMe = Plumber().peek<Me>();
    if (currentMe.socialLink != null) {
      _currentPanel = LoginPage.link;
    } else {
      // Defaulting to registration panel for the moment
      // _currentPanel = LoginPage.login;
      _currentPanel = LoginPage.register;
    }
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
      unawaited(UserManager().loadMe());
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
      unawaited(UserManager().loadMe());
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
      case LoginPage.link:
        return _linkAccountsForm();
      case LoginPage.login:
      default:
        return _loginForm();
    }
  }

  Future<void> _linkAccounts(bool shouldLink) async {
    if (_buttonDisabled) {
      return;
    }

    _disableButton(true);
    try {
      await UserManager().linkAccounts(shouldLink);
      if (!shouldLink) {
        // If we canceled the link
        _disableButton(false);
        _selectPanel(LoginPage.login);
      }
    } on Exception catch (_) {
      _disableButton(false);
    }
  }

  Widget _linkAccountsForm() {
    final theme = RiveTheme.of(context);
    final colors = theme.colors;
    final styles = theme.textStyles;

    final socialLink = Plumber().peek<Me>().socialLink;
    assert(socialLink != null);
    final socialEmail = socialLink.email;
    final socialName = socialLink.socialNetwork[0].toUpperCase() +
        socialLink.socialNetwork.substring(1);

    return Column(
      key: const ValueKey<int>(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
              style: styles.loginText.copyWith(height: 1.6),
              text: 'A Rive account associated with ',
              children: [
                TextSpan(
                  text: '$socialEmail',
                  style: styles.loginText.copyWith(
                    height: 1.6,
                    fontWeight: FontWeight.bold,
                    color: colors.textButtonDark,
                  ),
                ),
                const TextSpan(
                    text: ' already exists.'
                        '\nDo you want to link it with your '),
                TextSpan(
                  text: '$socialName',
                  style: styles.loginText.copyWith(
                    height: 1.6,
                    fontWeight: FontWeight.bold,
                    color: colors.textButtonDark,
                  ),
                ),
                const TextSpan(text: ' account?'),
              ]),
        ),
        const SizedBox(height: 40),
        Row(
          children: [
            SizedBox(
              width: 145,
              child: FlatIconButton(
                label: 'Link Account',
                onTap: () => _linkAccounts(true),
                color: _buttonDisabled
                    ? colors.buttonDarkDisabled
                    : colors.textButtonDark,
                textColor: _buttonDisabled
                    ? colors.buttonDarkDisabledText
                    : Colors.white,
                hoverColor: _buttonDisabled
                    ? colors.buttonDarkDisabled
                    : colors.textButtonDark,
                hoverTextColor: Colors.white,
                radius: 20,
                elevation: flatButtonIconElevation,
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ),
            const SizedBox(width: 30),
            SizedBox(
              width: 145,
              child: FlatIconButton(
                label: 'Cancel',
                onTap: () => _linkAccounts(false),
                color: colors.textButtonLight,
                textColor: colors.buttonLightText,
                hoverColor: colors.textButtonLightHover,
                hoverTextColor: colors.buttonLightText,
                radius: 20,
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ),
          ],
        ),
      ],
    );
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

  Future<void> _socialLogin(AuthAction auth) async {
    if (_buttonDisabled) {
      return;
    }
    _disableButton(true);
    final authResponse = await auth();
    if (authResponse.isMessage) {
      unawaited(UserManager().loadMe());
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
                  _socialLogin(auth.loginApple); 
                },
        ),
        const SizedBox(width: 10),*/
        _SocialSigninButton(
          label: 'Google',
          icon: PackedIcon.signinGoogle,
          onTap: _buttonDisabled
              ? null
              : () async {
                  final api = RiveContext.of(context).api;
                  final auth = RiveAuth(api);
                  await _socialLogin(
                      isRegister ? auth.registerGoogle : auth.loginGoogle);
                },
        ),
        const SizedBox(width: 10),
        _SocialSigninButton(
          label: 'Facebook',
          icon: PackedIcon.signinFacebook,
          onTap: _buttonDisabled
              ? null
              : () async {
                  final api = RiveContext.of(context).api;
                  final auth = RiveAuth(api);
                  await _socialLogin(
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
                  // await _socialLogin(
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

  Widget _panelContents(RiveColors colors) {
    return SizedBox(
        width: 473,
        height: 618,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top padding.
            const SizedBox(height: 160),
            TintedIcon(
              icon: PackedIcon.riveLogoLogin,
              color: colors.loginLogo,
            ),
            const SizedBox(height: 55),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 100),
              child: _visibleForm,
              layoutBuilder: (currentChild, _) => currentChild,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            ),
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              child: Stack(
                children: [
                  Positioned(
                    right: 30,
                    top: 30,
                    child: _LoginSwitch(
                      panel: _currentPanel,
                      onSelect: _selectPanel,
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: _panelContents(
                      colors,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
      case LoginPage.link:
        // Don't show on linking page.
        return const SizedBox();
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
            toggle: () => onSelect(panel == LoginPage.login
                ? LoginPage.register
                : LoginPage.login),
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
  final Iterable<PackedIcon> icon;
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
