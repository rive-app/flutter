import 'package:rive_api/data_model.dart';

// token Token class
class Token {
  const Token({this.token});

  final String token;

  factory Token.fromDM(TokenDM token) => Token(token: token.token);
}
