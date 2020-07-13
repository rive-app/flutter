import 'dart:io';

import 'package:aws_client/aws_client.dart';
import 'package:aws_client/s3.dart';
import 'package:aws_client/sqs.dart';
import 'package:http_client/console.dart';

SqsQueue getQueue() {
  if (Platform.environment['AWS_ACCESS_KEY'] == null ||
      Platform.environment['AWS_SECRET_KEY'] == null ||
      Platform.environment['AWS_QUEUE'] == null) {
    throw Exception('Environment variables "AWS_ACCESS_KEY", "AWS_SECRET_KEY" '
        'and "AWS_QUEUE" are required to be set.');
  }

  var credentials = Credentials(
      accessKey: Platform.environment['AWS_ACCESS_KEY'],
      secretKey: Platform.environment['AWS_SECRET_KEY']);

  var aws = Aws(credentials: credentials, httpClient: ConsoleClient());
  return aws.sqs.queue(Platform.environment['AWS_QUEUE']);
}
