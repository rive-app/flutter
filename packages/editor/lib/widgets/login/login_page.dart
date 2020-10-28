enum LoginPage { login, register, recover, link, reset }

extension LoginPageName on LoginPage {
  String get name {
    switch (this) {
      case LoginPage.login:
        return 'login';
      case LoginPage.register:
        return 'register';
      case LoginPage.reset:
        return 'reset';
      case LoginPage.recover:
        return 'recover';
      case LoginPage.link:
        return 'link';
      default:
        return 'register';
    }
  }

  static LoginPage fromName(String pageName) {
    switch (pageName) {
      case 'login':
        return LoginPage.login;
      case 'register':
        return LoginPage.register;
      case 'recover':
        return LoginPage.recover;
      case 'link':
        return LoginPage.link;
      case 'reset':
        return LoginPage.reset;
      default:
        return LoginPage.register;
    }
  }
}

class LoginPageData {
  final LoginPage page;
  final String token;
  const LoginPageData(this.page, {this.token});
}