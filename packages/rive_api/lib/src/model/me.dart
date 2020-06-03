import 'package:meta/meta.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/data_model.dart';

/// Data model for a logged-in user

class Me extends User {
  const Me({
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
    this.socialLink,
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
  final SocialLink socialLink;

  factory Me.fromDM(MeDM me) => Me(
        signedIn: me?.signedIn,
        id: me?.id,
        ownerId: me?.ownerId,
        name: me?.name,
        username: me?.username,
        avatarUrl: me?.avatarUrl,
        isAdmin: me?.isAdmin,
        isPaid: me?.isPaid,
        notificationCount: me?.notificationCount,
        verified: me?.verified,
        notice: me?.notice,
        socialLink: me?.socialLink,
      );

  bool get isEmpty => ownerId == null;

  @override
  bool operator ==(Object o) => o is Me && o.ownerId == ownerId;

  @override
  int get hashCode => ownerId;

  @override
  String toString() {
    if (socialLink == null) {
      return 'Me($ownerId, $name)';
    } else {
      return '<SocialLinkMe: ($socialLink)>';
    }
  }

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
