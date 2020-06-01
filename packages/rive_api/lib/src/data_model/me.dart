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
  String toString() {
    if (socialLink == null) {
      return 'MeDM($id, $name)';
    } else {
      return '<SocialLinkMe: ($socialLink)>';
    }
  }
}

class SocialLink {
  const SocialLink({
    @required this.socialNetwork,
    @required this.email,
  });

  final String socialNetwork;
  final String email;
}
