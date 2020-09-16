import 'package:url_launcher/url_launcher.dart';

/// Utilities for launching external urls

void launchSupportUrl() => launchUrl('https://feedback.rive.app/');
void launchHelpUrl() => launchUrl('https://help.rive.app/');
void launchRuntimesUrl() => launchUrl('https://help.rive.app/runtimes/overview');

Future<void> launchUrl(final String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw Exception('Could not launch $url');
  }
}
