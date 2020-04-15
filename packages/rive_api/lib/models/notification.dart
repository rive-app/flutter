import 'package:meta/meta.dart';

import 'package:rive_api/src/deserialize_helper.dart';

/// Different notification types that can come from the Rive back end
/// Only showing the types currently handled by the Rive app
enum NotificationType {
  follow,
  teamInvite,
}

/// Returns the notification type from a string
NotificationType notificationTypeFromString(String value) {
  switch (value) {
    case 'team_invite':
      return NotificationType.teamInvite;
    case 'follow':
    default:
      return NotificationType.follow;
  }
}

/// Base notification class that has a factory that will construct
/// the appropriate concrete notification
class RiveNotification {
  const RiveNotification(this.dateTime);
  final DateTime dateTime;

  /// Builds a list of notifications from json data
  static List<RiveNotification> fromDataList(dataList) => dataList
      .map<RiveNotification>((data) => RiveNotification.fromData(data))
      .toList(growable: false);

  /// Builds the right type of notification based on json data
  factory RiveNotification.fromData(Map<String, dynamic> data) {
    final type = notificationTypeFromString(data['type']);
    switch (type) {
      case NotificationType.teamInvite:
        return RiveTeamInviteNotification(
          dateTime:
              DateTime.fromMillisecondsSinceEpoch(data.getInt('date') * 1000),
          senderId: data.getInt('senderId'),
          senderName: data.getString('senderName'),
          teamId: data.getInt('teamId'),
          teamName: data.getString('teamName'),
          inviteId: data.getInt('inviteId'),
        );
      case NotificationType.follow:
      default:
        return RiveFollowNotification(
          dateTime:
              DateTime.fromMillisecondsSinceEpoch(data.getInt('date') * 1000),
          senderId: data.getInt('senderId'),
          senderName: data.getString('senderName'),
        );
    }
  }
}

/// A follow notification
/// Contains the follower id (sendId) and name (senderName)
class RiveFollowNotification extends RiveNotification {
  const RiveFollowNotification({
    @required DateTime dateTime,
    @required this.senderId,
    @required this.senderName,
  }) : super(dateTime);

  final int senderId;
  final String senderName;
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
  }) : super(dateTime);

  final int senderId;
  final String senderName;
  final int teamId;
  final String teamName;
  final int inviteId;
}
