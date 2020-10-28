import 'package:meta/meta.dart';
import 'package:rive_api/data_model.dart';
import 'package:utilities/deserialize.dart';

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
    this.socialLink,
    this.isFirstRun = false,
    this.lastAnnoucementRead,
  }) : super(
          ownerId: ownerId,
          name: name,
          username: username,
          avatarUrl: avatarUrl,
        );

  final int id;
  final bool signedIn;
  final bool isAdmin;
  final bool isPaid;
  final bool verified;
  final bool isFirstRun;
  final int notificationCount;
  final String notice;
  final SocialLink socialLink;
  final DateTime lastAnnoucementRead;

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
  ///    'isFirstRun': true
  /// }
  factory MeDM.fromData(Map<String, dynamic> data) => MeDM(
        ownerId: data.getInt('ownerId'),
        name: data.getString('name'),
        signedIn: data.getBool('signedIn'),
        id: data.getInt('id'),
        username: data.getString('username'),
        avatarUrl: data.getString('avatar'),
        isAdmin: data.getBool('isAdmin'),
        isPaid: data.getBool('isPaid'),
        notificationCount: data.getInt('notificationCount'),
        verified: data.getBool('verified'),
        notice: data.getString('notice'),
        isFirstRun: data.getBool('isFirstRun'),
        lastAnnoucementRead: data.getDateTime('lastAnnouncementRead'),
      );

  /// Create a model from JSON data
  ///
  /// {
  ///   nm: [google|facebook|twitter],
  ///   em: user@rive.app,
  /// }
  ///
  /// This model is for a user that can connect their social account
  /// to their Rive account. No detail other than the social network name
  /// and the email associated with the account are provided.
  factory MeDM.fromSocialLink(Map<String, Object> data) => MeDM(
      ownerId: null,
      name: null,
      signedIn: false,
      id: null,
      socialLink: SocialLink(
        socialNetwork: data.getString('nm'),
        email: data.getString('em'),
      ));

  @override
  String toString() =>
      socialLink == null ? 'MeDM($id, $name)' : '<SocialLinkMe: ($socialLink)>';
}

class SocialLink {
  const SocialLink({
    @required this.socialNetwork,
    @required this.email,
  });

  final String socialNetwork;
  final String email;
}
