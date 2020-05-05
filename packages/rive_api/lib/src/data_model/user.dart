import 'package:utilities/deserialize.dart';
import 'package:meta/meta.dart';
import 'owner.dart';

class User extends Owner {
  const User({
    @required this.ownerId,
    @required this.name,
    @required this.username,
    @required this.avatarUrl,
  });
  final int ownerId;
  final String name;
  final String username;
  final String avatarUrl;

  static Iterable<User> fromSearchDataList(List<dynamic> data) =>
      data.map((d) => User.fromSearchData(d));

  factory User.fromSearchData(Map<String, dynamic> data) => User(
        ownerId: data.getInt('i'),
        name: data.getString('l'),
        username: data.getString('n'),
        avatarUrl: data.getString('a'),
      );

  @override
  String toString() => 'User($ownerId, $name)';

  @override
  bool operator ==(o) => o is User && o.ownerId == ownerId;

  @override
  int get hashCode => ownerId;

  /// Data to generate a test team
  static const _testData = {
    "n": "pollux",
    "i": 40836,
    "l": "Guido Rosso",
    "a": "https://cdn.2dimensions.com/avatars/40836-1-1570241275-krypton"
  };

  /// Create a test user
  factory User.testData() => User.fromSearchData(_testData);
}
