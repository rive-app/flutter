import 'package:rive_api/src/data_model/data_model.dart';
import 'package:meta/meta.dart';
import 'owner.dart';

/// Data model for a logged-in user

class Me extends Owner {
  const Me({
    @required this.signedIn,
    @required this.id,
    @required this.ownerId,
    @required this.name,
    this.username,
    this.avatarUrl,
    this.isAdmin,
    this.isPaid,
    this.notificationCount,
    this.verified,
    this.notice,
  });
  final bool signedIn;
  final int id;
  final int ownerId;
  final String name;
  final String username;
  final String avatarUrl;
  final bool isAdmin;
  final bool isPaid;
  final int notificationCount;
  final bool verified;
  final String notice;

  factory Me.fromDM(MeDM me) => Me(
        signedIn: me.signedIn,
        id: me.id,
        ownerId: me.ownerId,
        name: me.name,
        username: me.username,
        avatarUrl: me.avatarUrl,
        isAdmin: me.isAdmin,
        isPaid: me.isPaid,
        notificationCount: me.notificationCount,
        verified: me.verified,
        notice: me.notice,
      );

  @override
  bool operator ==(o) => o is Me && o.ownerId == ownerId;

  @override
  int get hashCode => ownerId;

  @override
  String toString() => 'Me($ownerId, $name)';

  @override
  MeDM get asDM => MeDM(
        signedIn: signedIn,
        id: id,
        ownerId: ownerId,
        name: name,
        username: username,
        avatarUrl: avatarUrl,
        isAdmin: isAdmin,
        isPaid: isPaid,
        notificationCount: notificationCount,
        verified: verified,
        notice: notice,
      );
}
