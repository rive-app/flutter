import 'package:url_launcher/url_launcher.dart';

/// Utilities for launching external urls

void launchSupportUrl() => launchUrl('https://feedback.rive.app/');
void launchHelpUrl() => launchUrl('https://help.rive.app/');
void launchRuntimesUrl() => launchUrl('https://help.rive.app/runtimes/overview');
void launchTermsUrl() => launchUrl('https://help.rive.app/legal/terms-of-service');
void launchPrivacyUrl() => launchUrl('https://help.rive.app/legal/privacy-policy');

Future<void> launchUrl(final String url) async {
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw Exception('Could not launch $url');
  }
}
