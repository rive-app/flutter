import 'package:meta/meta.dart';

import 'package:utilities/deserialize.dart';

/// Different notification types that can come from the Rive back end
/// Only showing the types currently handled by the Rive app
enum NotificationType {
  follow,
  teamInvite,
  teamInviteAccepted,
  teamInviteRejected,
  teamInviteRescinded,
  unknown,
}

/// Maps an int to a NotificationType
NotificationType notificationTypeFromInt(int value) {
  switch (value) {
    case 0:
      return NotificationType.follow;
    case 20:
      return NotificationType.teamInvite;
    case 21:
      return NotificationType.teamInviteAccepted;
    case 22:
      return NotificationType.teamInviteRejected;
    case 23:
      return NotificationType.teamInviteRescinded;
    default:
      return NotificationType.unknown;
  }
}

/// Base notification class that has a factory that will construct
/// the appropriate concrete notification
class RiveNotification {
  const RiveNotification(this.dateTime);
  final DateTime dateTime;

  /// Builds a list of notifications from json data
  static List<RiveNotification> fromDataList(List<dynamic> dataList) => dataList
      .map<RiveNotification>((data) => RiveNotification.fromData(data))
      .toList(growable: false);

  /// Builds the right type of notification based on json data
  factory RiveNotification.fromData(Map<String, dynamic> data) {
    final type = notificationTypeFromInt(data['t']);
    // Need to explicitly cast here for the extension methods to work
    final userData = data['u'] as Map<String, dynamic>;

    switch (type) {
      case NotificationType.teamInvite:
        final teamData = data['m'] as Map<String, dynamic>;
        assert(teamData != null, 'no team data? what gives?');
        return RiveTeamInviteNotification(
          dateTime:
              DateTime.fromMillisecondsSinceEpoch(data.getInt('w') * 1000),
          senderId: userData.getInt('oi'),
          senderName: userData.getString('nm') ?? userData.getString('un'),
          teamId: teamData.getInt('ti'),
          teamName: teamData.getString('tn'),
          inviteId: teamData.getInt('ii'),
          permission: teamData.getInt('pn'),
          avatarUrl: teamData.getString('av'),
        );
      case NotificationType.teamInviteAccepted:
        final teamData = data['m'] as Map<String, dynamic>;
        return RiveTeamInviteAcceptedNotification(
          dateTime:
              DateTime.fromMillisecondsSinceEpoch(data.getInt('w') * 1000),
          teamId: teamData.getInt('ti'),
          teamName: teamData.getString('tn'),
          avatarUrl: teamData.getString('av'),
        );
      case NotificationType.teamInviteRejected:
        final teamData = data['m'] as Map<String, dynamic>;
        return RiveTeamInviteRejectedNotification(
          dateTime:
              DateTime.fromMillisecondsSinceEpoch(data.getInt('w') * 1000),
          teamId: teamData.getInt('ti'),
          teamName: teamData.getString('tn'),
          avatarUrl: teamData.getString('av'),
        );
      case NotificationType.teamInviteRescinded:
        final teamData = data['m'] as Map<String, dynamic>;
        return RiveTeamInviteRescindedNotification(
          dateTime:
              DateTime.fromMillisecondsSinceEpoch(data.getInt('w') * 1000),
          teamId: teamData.getInt('ti'),
          teamName: teamData.getString('tn'),
          avatarUrl: teamData.getString('av'),
        );
      // New follower notification:
      // {"u":{"oi":40842,"pf":11,"un":"matt","nm":"Matt","av":null,"fl":1,"f1":1,"f2":2,"bg":null,"s1":null,"s2":null},"t":0,"w":1587171124}
      case NotificationType.follow:
        return RiveFollowNotification(
          dateTime:
              DateTime.fromMillisecondsSinceEpoch(data.getInt('w') * 1000),
          followerId: userData.getInt('oi'),
          followerName: userData.getString('nm'),
          followerUsername: userData.getString('un'),
        );

      case NotificationType.unknown:
      default:
        return RiveNotification(
          DateTime.fromMillisecondsSinceEpoch(data.getInt('w') * 1000),
        );
    }
  }
}

/// A follow notification
/// Contains the follower id (sendId) and name (senderName)
class RiveFollowNotification extends RiveNotification {
  const RiveFollowNotification({
    @required this.followerId,
    @required this.followerName,
    @required this.followerUsername,
    @required DateTime dateTime,
  }) : super(dateTime);

  final int followerId;
  final String followerName;
  final String followerUsername;
}

/// A team invite notification
/// Contains the inviter (senderId), inviter name (senderName)
/// team id (teamId), team name (teamName), and invite id (inviteId)
class RiveTeamInviteNotification extends RiveNotification {
  const RiveTeamInviteNotification({
    @required DateTime dateTime,
    @required this.senderId,
    @required this.senderName,
    @required this.teamId,
    @required this.teamName,
    @required this.inviteId,
    @required this.permission,
    @required this.avatarUrl,
  }) : super(dateTime);

  final int senderId;
  final String senderName;
  final int teamId;
  final String teamName;
  final int inviteId;
  final int permission;
  final String avatarUrl;
}

class RiveTeamInviteAcceptedNotification extends RiveNotification {
  const RiveTeamInviteAcceptedNotification({
    @required DateTime dateTime,
    @required this.teamId,
    @required this.teamName,
    @required this.avatarUrl,
  }) : super(dateTime);

  final int teamId;
  final String teamName;
  final String avatarUrl;
}

class RiveTeamInviteRejectedNotification extends RiveNotification {
  const RiveTeamInviteRejectedNotification({
    @required DateTime dateTime,
    @required this.teamId,
    @required this.teamName,
    @required this.avatarUrl,
  }) : super(dateTime);

  final int teamId;
  final String teamName;
  final String avatarUrl;
}

class RiveTeamInviteRescindedNotification extends RiveNotification {
  const RiveTeamInviteRescindedNotification({
    @required DateTime dateTime,
    @required this.teamId,
    @required this.teamName,
    @required this.avatarUrl,
  }) : super(dateTime);

  final int teamId;
  final String teamName;
  final String avatarUrl;
}
