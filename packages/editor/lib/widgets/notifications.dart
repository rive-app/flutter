import 'package:flutter/material.dart';
import 'package:rive_api/apis/changelog.dart';
import 'package:rive_editor/widgets/common/underline.dart';

import 'package:rive_editor/widgets/inherited_widgets.dart';

/// Placeholder for the notifications panel
class NotificationsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // theme.colors.panelBackgroundLightGrey,
      child: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 680,
                  child: OverflowBox(
                    alignment: Alignment.centerLeft,
                    minWidth: 680,
                    maxWidth: 680,
                    child: NotificationsLoader(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsLoader extends StatefulWidget {
  @override
  _NotificationsLoaderState createState() => _NotificationsLoaderState();
}

class _NotificationsLoaderState extends State<NotificationsLoader> {
  Future<List<Changelog>> _changelogs;

  @override
  void initState() {
    _changelogs = fetchChangelogs();
    super.initState();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
        future: _changelogs,
        builder: (context, AsyncSnapshot<List<Changelog>> snapshot) =>
            snapshot.hasData
                ? NotificationsList(snapshot.data)
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
      );
}

class NotificationsList extends StatelessWidget {
  const NotificationsList(this.changelogs);
  final List<Changelog> changelogs;

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      const SizedBox(height: 30),
      NotificationsHeader(),
      for (final changelog in changelogs) ...[
        const SizedBox(height: 30),
        ChangelogNotification(changelog)
      ]
    ]);
  }
}

class ChangelogNotification extends StatelessWidget {
  const ChangelogNotification(this.changelog);
  final Changelog changelog;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colors.panelBackgroundLightGrey,
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Rive ${changelog.version} Changelog',
              style: theme.textStyles.notificationTitle,
            ),
            const SizedBox(height: 10),
            for (final item in changelog.items) ...[
              Text(
                item.title,
                style: theme.textStyles.notificationTitle,
              ),
              const SizedBox(height: 5),
              Text(
                item.description,
                style: theme.textStyles.notificationText,
              ),
              const SizedBox(height: 5),
            ]
          ],
        ),
      ),
    );
  }
}

class NotificationsHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);
    return Underline(
      color: theme.colors.panelBackgroundLightGrey,
      thickness: 1,
      offset: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            'For You',
            style: theme.textStyles.notificationHeader,
          ),
          const SizedBox(width: 30),
          Text(
            'Announcements',
            style: theme.textStyles.notificationHeaderSelected,
          ),
        ],
      ),
    );
  }
}
