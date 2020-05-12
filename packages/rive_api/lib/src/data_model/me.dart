import 'package:meta/meta.dart';
import 'package:utilities/deserialize.dart';

import 'data_model.dart';

/// Data model for a logged-in user

class MeDM extends UserDM {
  const MeDM({
    @required int ownerId,
    @required String name,
    @required this.signedIn,
    @required this.id,
    String username,
    String avatarUrl,
    this.isAdmin,
    this.isPaid,
    this.notificationCount,
    this.verified,
    this.notice,
  }) : super(
          ownerId: ownerId,
          name: name,
          username: username,
          avatarUrl: avatarUrl,
        );

  final bool signedIn;
  final int id;
  final bool isAdmin;
  final bool isPaid;
  final int notificationCount;
  final bool verified;
  final String notice;

  /// Creates a model from JSON:
  ///
  /// {
  ///   'signedIn':true,
  ///    'id':40877,
  ///    'ownerId':40955,
  ///    'name':'Demo',
  ///    'username':'demo',
  ///    'avatar':null,
  ///    'isAdmin':false,
  ///    'isPaid':false,
  ///    'notificationCount':0,
  ///    'verified':false,
  ///    'notice':'confirm-email'
  /// }
  factory MeDM.fromData(Map<String, dynamic> data) => MeDM(
        signedIn: data.getBool('signedIn'),
        id: data.getInt('id'),
        ownerId: data.getInt('ownerId'),
        name: data.getString('name'),
        username: data.getString('username'),
        avatarUrl: data.getString('avatar'),
        isAdmin: data.getBool('isAdmin'),
        isPaid: data.getBool('isPaid'),
        notificationCount: data.getInt('notificationCount'),
        verified: data.getBool('verified'),
        notice: data.getString('notice'),
      );

  @override
  String toString() => 'MeDM($id, $name)';
}
