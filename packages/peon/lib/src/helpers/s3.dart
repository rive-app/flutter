import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:aws_client/src/request.dart';
import 'package:aws_client/src/credentials.dart';
import 'package:http_client/console.dart';

Credentials getCredentials() {
  return Credentials(
      accessKey: Platform.environment['AWS_ACCESS_KEY'],
      secretKey: Platform.environment['AWS_SECRET_KEY']);
}

Future<String> getS3Key(String sourceLocation) async {
  // Watch out here, the capitalization in the header is important.
  // lowercase it will mess with the signature and break it.
  var client = ConsoleClient();
  try {
    var getRequest = AwsRequestBuilder(
        body: [],
        headers: {'X-Amz-Content-Sha256': sha256.convert([]).toString()},
        region: 'us-east-1',
        uri: Uri.parse(sourceLocation),
        credentials: getCredentials(),
        httpClient: client,
        service: 's3');

    final response = await getRequest.sendRequest();
    final data = await response.readAsString();
    return data;
  } finally {
    client.close();
  }
}

Future<void> putS3Key(targetLocation, Uint8List payload) async {
  // Watch out here, the capitalization in the header is important.
  // lowercase it will mess with the signature and break it.
  var client = ConsoleClient();
  try {
    var putRequest = AwsRequestBuilder(
        method: 'PUT',
        body: payload,
        headers: {'X-Amz-Content-Sha256': sha256.convert(payload).toString()},
        region: 'us-east-1',
        uri: Uri.parse(targetLocation),
        credentials: getCredentials(),
        httpClient: client,
        service: 's3');
    await putRequest.sendRequest();
  } finally {
    await client.close();
  }
}
