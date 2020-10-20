import 'package:sentry/sentry.dart';
import 'package:utilities/environment.dart';

// coop server project dsn:
// 'https://1ea8934c37fb4d948c7b057827db4e4d@sentry.io/3764728'
// rive-6q project dsn:
const defaultSentryDSN =
    'https://cd4c5a674f8e44f49203ce39d47c236c@sentry.io/3876713';

final _sentryEnvironment = getVariable(
  'SENTRY_ENV',
  defaultValue: const String.fromEnvironment(
    'SENTRY_ENV',
    defaultValue: 'development',
  ),
);

// Sentry config
final sentryClient = SentryClient(
  dsn: getVariable(
    'SENTRY_DSN',
    defaultValue: const String.fromEnvironment(
      'SENTRY_DSN',
      defaultValue: defaultSentryDSN,
    ),
  ),
  // set up environment value sent with every event.
  environmentAttributes: Event(
    environment: _sentryEnvironment,
  ),
);
