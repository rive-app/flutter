import 'dart:async';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:aws_client/src/request.dart';
import 'package:http_client/console.dart';
import 'package:peon/src/queue.dart';

Future<String> getS3Key(String sourceLocation) async {
  // Watch out here, the capitalization in the header is important.
  // lowercase it will mess with the signature and break it.
  var client = ConsoleClient();

  // TODO: pr this back into the aws client, it should add the session token
  // before signing.
  var credentials = await getCredentials();
  var headers = <String, String>{
    'X-Amz-Content-Sha256': sha256.convert([]).toString()
  };
  if (credentials.sessionToken != null) {
    headers['X-Amz-Security-Token'] = credentials.sessionToken;
  }
  try {
    var getRequest = AwsRequestBuilder(
        body: [],
        headers: headers,
        region: 'us-east-1',
        uri: Uri.parse(sourceLocation),
        credentials: credentials,
        httpClient: client,
        service: 's3');

    final response = await getRequest.sendRequest();
    final data = await response.readAsString();
    return data;
  } finally {
    await client.close();
  }
}

Future<void> putS3Key(String targetLocation, Uint8List payload) async {
  // Watch out here, the capitalization in the header is important.
  // lowercase it will mess with the signature and break it.
  var credentials = await getCredentials();
  var headers = <String, String>{
    'X-Amz-Content-Sha256': sha256.convert(payload).toString()
  };
  if (credentials.sessionToken != null) {
    headers['X-Amz-Security-Token'] = credentials.sessionToken;
  }

  var client = ConsoleClient();
  try {
    var putRequest = AwsRequestBuilder(
        method: 'PUT',
        body: payload,
        headers: headers,
        region: 'us-east-1',
        uri: Uri.parse(targetLocation),
        credentials: credentials,
        httpClient: client,
        service: 's3');

    final response = await putRequest.sendRequest();
    assert(response.statusCode == 200);
  } finally {
    await client.close();
  }
}
