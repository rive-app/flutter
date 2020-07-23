import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aws_client/aws_client.dart';
import 'package:aws_client/src/credentials.dart';
import 'package:aws_client/sqs.dart';
import 'package:http_client/console.dart';

// jesus christ dart.
Future<String> readResponse(HttpClientResponse response) {
  final completer = Completer<String>();
  final contents = StringBuffer();
  response.transform(utf8.decoder).listen(contents.write,
      onDone: () => completer.complete(contents.toString()));
  return completer.future;
}

Future<Credentials> getCredentials() async {
  // if this works we should look at memoizing the 'getCredentials' for `a bit`

  if (Platform.environment['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'] != null) {
    // https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html
    var relativeUrl =
        Platform.environment['AWS_CONTAINER_CREDENTIALS_RELATIVE_URI'];
    var client = HttpClient();
    try {
      var request =
          await client.getUrl(Uri.parse('http://169.254.170.2$relativeUrl'));
      var response = await request.close();
      var responseBody = await readResponse(response);
      // {
      //     "AccessKeyId": "ACCESS_KEY_ID",
      //     "Expiration": "EXPIRATION_DATE",
      //     "RoleArn": "TASK_ROLE_ARN",
      //     "SecretAccessKey": "SECRET_ACCESS_KEY",
      //     "Token": "SECURITY_TOKEN_STRING"
      // }
      var jsonResponse = json.decode(responseBody) as Map<String, Object>;
      // {AccessKeyId: ASIAZQ5X7BHGINZUSCVX, Expiration: 2020-07-23T16:26:38Z, RoleArn: , SecretAccessKey: xxx, Token: xxx}
      return Credentials(
          accessKey: jsonResponse['AccessKeyId'] as String,
          secretKey: jsonResponse['SecretAccessKey'] as String,
          sessionToken: jsonResponse['Token'] as String);
    } finally {
      client.close();
    }
  } else if (Platform.environment['AWS_ACCESS_KEY'] != null &&
      Platform.environment['AWS_SECRET_KEY'] != null) {
    return Credentials(
        accessKey: Platform.environment['AWS_ACCESS_KEY'],
        secretKey: Platform.environment['AWS_SECRET_KEY']);
  } else {
    throw Exception(
        'Either "AWS_CONTAINER_CREDENTIALS_RELATIVE_URI" or variables '
        '"AWS_ACCESS_KEY", "AWS_SECRET_KEY" are '
        'required to get AWS Credentials.');
  }
}

Future<SqsQueue> getQueue() async {
  if (Platform.environment['AWS_DART_QUEUE'] == null) {
    throw Exception('"AWS_DART_QUEUE" is required.');
  }

  var credentials = await getCredentials();
  var aws = Aws(credentials: credentials, httpClient: ConsoleClient());
  return aws.sqs.queue(Platform.environment['AWS_DART_QUEUE']);
}

Future<SqsQueue> getJSQueue() async {
  if (Platform.environment['AWS_JS_QUEUE'] == null) {
    throw Exception('"AWS_JS_QUEUE" are required.');
  }

  var credentials = await getCredentials();
  var aws = Aws(credentials: credentials, httpClient: ConsoleClient());
  return aws.sqs.queue(Platform.environment['AWS_JS_QUEUE']);
}
