import 'package:rive_api/model.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/models/team_role.dart';

CurrentDirectory getCurrentDirectory({Owner owner, int folderId = 1}) {
  var _owner = owner;
  if (owner == null) {
    _owner = getOwner();
  }
  return CurrentDirectory(_owner, folderId);
}

Owner getOwner({int ownerId = 1}) {
  return Team(
    ownerId: ownerId,
    username: 'TeamUsername',
    name: 'Name',
    permission: TeamRole.admin,
  );
}

Me getMe({int ownerId = 1}) {
  return Me(
    ownerId: ownerId,
    username: 'TeamUsername',
    name: 'Name',
    id: ownerId,
    signedIn: true,
  );
}

List<NotificationDM> getTestNotifications() {
  final now = DateTime.now();
  const followerId = 1;
  const followerUsername = 'heman';
  const followerName = 'Herman';
  const senderId = 2;
  const senderName = 'Klaus';
  const teamId = 3;
  const teamName = 'Mein Team';
  const url = 'https://tinyurl.com/3b6g7nl';
  const inviteId = 1;
  const permission = 0;
  return [
    NotificationDM(
      now,
    ),
    FollowNotificationDM(
      followerId: followerId,
      followerUsername: followerUsername,
      followerName: followerName,
      dateTime: now,
    ),
    TeamInviteNotificationDM(
        senderId: senderId,
        senderName: senderName,
        teamId: teamId,
        teamName: teamName,
        avatarUrl: url,
        inviteId: inviteId,
        permission: permission,
        dateTime: now),
    TeamInviteAcceptedNotificationDM(
      teamId: teamId,
      teamName: teamName,
      avatarUrl: url,
      dateTime: now,
    ),
    TeamInviteRejectedNotificationDM(
      teamId: teamId,
      teamName: teamName,
      avatarUrl: url,
      dateTime: now,
    ),
    TeamInviteRescindedNotificationDM(
      teamId: teamId,
      teamName: teamName,
      avatarUrl: url,
      dateTime: now,
    ),
  ];
}
