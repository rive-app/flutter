import 'package:utilities/deserialize.dart';

class Me {
  const Me({this.name, this.avatarUrl});
  final String name;
  final String avatarUrl;

  factory Me.fromData(Map<String, dynamic> data) =>
      Me(name: data.getString('name'), avatarUrl: data.getString('avatar'));

  @override
  String toString() => 'Me($name)';
}
