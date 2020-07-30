import 'package:flutter_test/flutter_test.dart';
import 'package:rive_editor/widgets/notifications.dart';
import 'package:rive_api/model.dart' as model;
import 'base.dart';

void main() {
  group('Follow Notification', () {
    testWidgets('Follow notification prioritizes name', (tester) async {
      var notification = model.FollowNotification(
          followerUsername: 'username',
          dateTime: DateTime.now(),
          followerId: 1,
          followerName: 'name');
      await tester
          .pumpWidget(bootstrapped(FollowNotificationWidget(notification)));
      final finder = find.text('name started following you.');
      expect(finder, findsOneWidget);
    });
    testWidgets('Follow notification falls back to username', (tester) async {
      var notification = model.FollowNotification(
          followerUsername: 'username',
          dateTime: DateTime.now(),
          followerId: 1,
          followerName: null);
      await tester
          .pumpWidget(bootstrapped(FollowNotificationWidget(notification)));
      final finder = find.text('username started following you.');
      expect(finder, findsOneWidget);
    });
  });
}
