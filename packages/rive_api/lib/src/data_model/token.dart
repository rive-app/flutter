import 'package:utilities/utilities.dart';
import 'package:meta/meta.dart';

class TokenDM {
  TokenDM({
    @required this.token,
  });
  final String token;

  factory TokenDM.fromData(Map<String, Object> data) {
    return TokenDM(
      token: data.getString('token'),
    );
  }
}
