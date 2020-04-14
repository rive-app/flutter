import 'package:meta/meta.dart';

import 'package:rive_api/src/deserialize_helper.dart';

/// Different notification types that can come from the Rive back end
enum NotificationType {
  follow,
  shotComment,
  shotLike,
  conversationReply,
  blogComment,
  blogMention,
  shotMention,
  conversationMention,
  yourShotComment,
  yourConversationReply,
  yourBlogComment,
  shotCommentMention,
  blogCommentMention,
  conversationReplyMention,
  acceptedInvitation,
  fileMention,
  fileCommentMention,
  fileLike,
  yourFileComment,
  fileComment,
}

/// Base notification class that has a factory that will construct
/// the appropriate concrete notification
class Notification {
  const Notification(
    this.dateTime,
  );
  final DateTime dateTime;

  /// Builds a list of notifications from json data
  static List<Notification> fromDataList(List<dynamic> dataList) => dataList
      .map((data) => Notification.fromData(data))
      .toList(growable: false);

  /// Builds the right type of notification based on json data
  factory Notification.fromData(Map<String, dynamic> data) {
    final type = notificationTypeFromString(data['type']);
    switch (type) {
      case NotificationType.follow:
      default:
        return FollowNotification(
          dateTime:
              DateTime.fromMillisecondsSinceEpoch(data.getInt('date') * 1000),
          senderId: data.getInt('senderId'),
        );
    }
  }
}

/// A follow notification; contains the follower (senderId)
class FollowNotification extends Notification {
  const FollowNotification({
    @required DateTime dateTime,
    this.senderId,
  }) : super(dateTime);

  final int senderId;
}

/// Returns the notification type from a string
NotificationType notificationTypeFromString(String value) {
  switch (value) {
    case 'follow':
    default:
      return NotificationType.follow;
  }
}
