import 'package:meta/meta.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/data_model.dart';

/// Data model for a logged-in user

class Me extends User {
  const Me({
    @required int ownerId,
    @required String name,
    @required this.id,
    String username,
    String avatarUrl,
    this.isAdmin,
    this.isPaid,
    this.notificationCount,
    this.verified,
    this.notice,
    this.socialLink,
    this.isFirstRun,
    this.signedIn = false,
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
  final bool isFirstRun;

  factory Me.fromDM(MeDM me) => Me(
        // lets not let signedIn be null
        signedIn: me?.signedIn ?? false,
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
        isFirstRun: me?.isFirstRun,
      );

  // Me.isEmpty is currently neccessary to hold onto 'social links'
  // during the sign up process
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
        isFirstRun: isFirstRun,
      );

  Me copyWith({String avatarUrl, String name, String username}) => Me(
        name: name ?? this.name,
        username: username ?? this.username,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        ownerId: ownerId,
        signedIn: signedIn,
        id: id,
        isAdmin: isAdmin,
        isPaid: isPaid,
        notificationCount: notificationCount,
        verified: verified,
        notice: notice,
        socialLink: socialLink,
        isFirstRun: isFirstRun,
      );
}
