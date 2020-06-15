import 'package:url_launcher/url_launcher.dart';

/// Utilities for launching external urls

void launchSupportUrl() => launchUrl('https://rive.nolt.io/');
void launchHelpUrl() => launchUrl('https://help.rive.app/');

Future<void> launchUrl(final String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw Exception('Could not launch $url');
  }
}
