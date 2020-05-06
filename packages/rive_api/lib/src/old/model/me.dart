// import 'package:utilities/deserialize.dart';
// import 'package:meta/meta.dart';

// /// Data model for a logged-in user

// class Me {
//   const Me({
//     @required this.signedIn,
//     @required this.id,
//     @required this.ownerId,
//     @required this.name,
//     this.username,
//     this.avatarUrl,
//     this.isAdmin,
//     this.isPaid,
//     this.notificationCount,
//     this.verified,
//     this.notice,
//   });
//   final bool signedIn;
//   final int id;
//   final int ownerId;
//   final String name;
//   final String username;
//   final String avatarUrl;
//   final bool isAdmin;
//   final bool isPaid;
//   final int notificationCount;
//   final bool verified;
//   final String notice;

//   /// Creates a model from JSON:
//   ///
//   /// {
//   ///   'signedIn':true,
//   ///    'id':40877,
//   ///    'ownerId':40955,
//   ///    'name':'Demo',
//   ///    'username':'demo',
//   ///    'avatar':null,
//   ///    'isAdmin':false,
//   ///    'isPaid':false,
//   ///    'notificationCount':0,
//   ///    'verified':false,
//   ///    'notice':'confirm-email'
//   /// }
//   factory Me.fromData(Map<String, dynamic> data) => Me(
//         signedIn: data.getBool('signedIn'),
//         id: data.getInt('id'),
//         ownerId: data.getInt('ownerId'),
//         name: data.getString('name'),
//         username: data.getString('username'),
//         avatarUrl: data.getString('avatar'),
//         isAdmin: data.getBool('isAdmin'),
//         isPaid: data.getBool('isPaid'),
//         notificationCount: data.getInt('notificationCount'),
//         verified: data.getBool('verified'),
//         notice: data.getString('notice'),
//       );

//   /// Data to generate a test user
//   static const _testData = {
//     'signedIn': true,
//     'id': 40877,
//     'ownerId': 40955,
//     'name': 'Matt',
//     'username': 'matt',
//     'avatar': 'http://example.avatar.com',
//     'isAdmin': false,
//     'isPaid': false,
//     'notificationCount': 0,
//     'verified': false,
//     'notice': 'confirm-email'
//   };

//   /// Create a test user
//   factory Me.testData() => Me.fromData(_testData);

//   @override
//   String toString() => 'Me($id, $name)';
// }
