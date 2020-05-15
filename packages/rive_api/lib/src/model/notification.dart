import 'package:meta/meta.dart';
import 'package:rive_api/src/data_model/data_model.dart';

/// Base notification class that has a factory that will construct
/// the appropriate concrete notification
class Notification {
  const Notification(this.dateTime);
  final DateTime dateTime;

  static List<Notification> fromDMList(List<NotificationDM> teams) =>
      teams.map((team) => Notification.fromDM(team)).toList();

  factory Notification.fromDM(NotificationDM invite) {
    if (invite is TeamInviteNotificationDM) {
      return TeamInviteNotification.fromDM(invite);
    } else if (invite is TeamInviteAcceptedNotificationDM) {
      return TeamInviteAcceptedNotification.fromDM(invite);
    } else if (invite is TeamInviteRejectedNotificationDM) {
      return TeamInviteRejectedNotification.fromDM(invite);
    } else if (invite is TeamInviteRescindedNotificationDM) {
      return TeamInviteRescindedNotification.fromDM(invite);
    } else if (invite is FollowNotificationDM) {
      return FollowNotification.fromDM(invite);
    } else {
      return Notification(invite.dateTime);
    }
  }
}

/// A follow notification
/// Contains the follower id (sendId) and name (senderName)
class FollowNotification extends Notification {
  const FollowNotification({
    @required this.followerId,
    @required this.followerName,
    @required this.followerUsername,
    @required DateTime dateTime,
  }) : super(dateTime);

  final int followerId;
  final String followerName;
  final String followerUsername;
  factory FollowNotification.fromDM(FollowNotificationDM invite) {
    return FollowNotification(
      followerId: invite.followerId,
      followerName: invite.followerName,
      followerUsername: invite.followerUsername,
      dateTime: invite.dateTime,
    );
  }
}

/// A team invite notification
/// Contains the inviter (senderId), inviter name (senderName)
/// team id (teamId), team name (teamName), and invite id (inviteId)
class TeamInviteNotification extends Notification {
  const TeamInviteNotification({
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

  factory TeamInviteNotification.fromDM(TeamInviteNotificationDM invite) {
    return TeamInviteNotification(
      senderId: invite.senderId,
      senderName: invite.senderName,
      teamId: invite.teamId,
      teamName: invite.teamName,
      inviteId: invite.inviteId,
      permission: invite.permission,
      avatarUrl: invite.avatarUrl,
      dateTime: invite.dateTime,
    );
  }
}

class TeamInviteAcceptedNotification extends Notification {
  const TeamInviteAcceptedNotification({
    @required DateTime dateTime,
    @required this.teamId,
    @required this.teamName,
    @required this.avatarUrl,
  }) : super(dateTime);

  final int teamId;
  final String teamName;
  final String avatarUrl;

  factory TeamInviteAcceptedNotification.fromDM(
      TeamInviteAcceptedNotificationDM invite) {
    return TeamInviteAcceptedNotification(
      teamId: invite.teamId,
      teamName: invite.teamName,
      avatarUrl: invite.avatarUrl,
      dateTime: invite.dateTime,
    );
  }
}

class TeamInviteRejectedNotification extends Notification {
  const TeamInviteRejectedNotification({
    @required DateTime dateTime,
    @required this.teamId,
    @required this.teamName,
    @required this.avatarUrl,
  }) : super(dateTime);

  final int teamId;
  final String teamName;
  final String avatarUrl;

  factory TeamInviteRejectedNotification.fromDM(
      TeamInviteRejectedNotificationDM invite) {
    return TeamInviteRejectedNotification(
      teamId: invite.teamId,
      teamName: invite.teamName,
      avatarUrl: invite.avatarUrl,
      dateTime: invite.dateTime,
    );
  }
}

class TeamInviteRescindedNotification extends Notification {
  const TeamInviteRescindedNotification({
    @required DateTime dateTime,
    @required this.teamId,
    @required this.teamName,
    @required this.avatarUrl,
  }) : super(dateTime);

  final int teamId;
  final String teamName;
  final String avatarUrl;

  factory TeamInviteRescindedNotification.fromDM(
      TeamInviteRescindedNotificationDM invite) {
    return TeamInviteRescindedNotification(
      teamId: invite.teamId,
      teamName: invite.teamName,
      avatarUrl: invite.avatarUrl,
      dateTime: invite.dateTime,
    );
  }
}
