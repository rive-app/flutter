import 'dart:io';

import 'package:aws_client/aws_client.dart';
import 'package:aws_client/s3.dart';
import 'package:aws_client/sqs.dart';
import 'package:http_client/console.dart';

SqsQueue getQueue() {
  var credentials = Credentials(
      accessKey: Platform.environment['AWS_ACCESS_KEY'],
      secretKey: Platform.environment['AWS_SECRET_KEY']);
  print(Platform.environment['AWS_ACCESS_KEY']);
  print(Platform.environment['AWS_SECRET_KEY']);
  print(Platform.environment['AWS_QUEUE']);
  var aws = Aws(credentials: credentials, httpClient: ConsoleClient());
  return aws.sqs.queue(Platform.environment['AWS_QUEUE']);
}
