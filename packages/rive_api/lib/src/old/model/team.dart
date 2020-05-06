// import 'package:utilities/deserialize.dart';
// import 'package:meta/meta.dart';

// class Team {
//   const Team({
//     @required this.ownerId,
//     @required this.name,
//     @required this.username,
//     @required this.permission,
//     this.avatarUrl,
//   });
//   final int ownerId;
//   final String name;
//   final String username;
//   final String avatarUrl;
//   final String permission;

//   static Iterable<Team> fromDataList(List<dynamic> data) =>
//       data.map((d) => Team.fromData(d));

//   factory Team.fromData(Map<String, dynamic> data) => Team(
//         ownerId: data.getInt('ownerId'),
//         name: data.getString('name'),
//         username: data.getString('username'),
//         avatarUrl: data.getString('avatar'),
//         permission: data.getString('permission'),
//       );

//   @override
//   String toString() => 'Team($ownerId, $name)';

//   @override
//   bool operator ==(o) => o is Team && o.ownerId == ownerId;

//   @override
//   int get hashCode => ownerId;

//   /// Data to generate a test team
//   static const _testData = {
//     'ownerId': 12345,
//     'name': 'Team Awesome',
//     'username': 'team_awesome',
//     'avatar': 'http://example.avatar.com',
//     'permission': 'member',
//   };

//   /// Create a test user
//   factory Team.testData() => Team.fromData(_testData);
// }
