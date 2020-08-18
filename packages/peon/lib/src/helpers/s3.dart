import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:aws_client/src/request.dart';
import 'package:aws_client/src/credentials.dart';
import 'package:http_client/console.dart';
import 'package:peon/src/queue.dart';

String getRegion() {
  return Platform.environment['AWS_REGION'] ?? 'us-east-1';
}

Future<Uint8List> getS3Key(String sourceLocation,
    [String regionOverride]) async {
  // Watch out here, the capitalization in the header is important.
  // lowercase it will mess with the signature and break it.
  var credentials = await getCredentials();
  var client = ConsoleClient();
  try {
    if (!await _exists(
      payload: Uint8List(0),
      credentials: credentials,
      region: regionOverride ?? getRegion(),
      uri: sourceLocation,
      client: client,
    )) {
      throw Exception('Could not get file from s3 [$sourceLocation]');
    }
    final response = await _request(
      method: 'GET',
      payload: Uint8List(0),
      credentials: credentials,
      region: regionOverride ?? getRegion(),
      uri: sourceLocation,
      client: client,
    );
    if (response.statusCode != 200) {
      var body = await response.readAsString();
      throw Exception(
          'Could not get file from s3, $sourceLocation, status ${response.statusCode}\n$body');
    }

    var intList = await response.readAsBytes();
    var data = Uint8List.fromList(intList);
    return data;
  } finally {
    await client.close();
  }
}

Future<void> putS3Key(String targetLocation, Uint8List payload,
    [String regionOverride]) async {
  // Watch out here, the capitalization in the header is important.
  // lowercase it will mess with the signature and break it.
  var credentials = await getCredentials();
  var client = ConsoleClient();
  try {
    final response = await _request(
      method: 'PUT',
      payload: payload,
      credentials: credentials,
      region: regionOverride ?? getRegion(),
      uri: targetLocation,
      client: client,
    );

    assert(response.statusCode == 200);
  } finally {
    await client.close();
  }
}

Future<bool> _exists({
  String uri,
  ConsoleClient client,
  Credentials credentials,
  Uint8List payload,
  String region,
  int attempts = 5,
}) async {
  int _attempts = attempts;
  while (_attempts-- > 0) {
    final response = await _request(
      method: 'GET',
      payload: payload,
      credentials: credentials,
      region: region,
      uri: uri,
      client: client,
    );
    if (response.statusCode == 200) {
      return true;
    }
    await Future<Object>.delayed(const Duration(seconds: 5));
  }
  return false;
}

Future<AwsResponse> _request({
  String uri,
  String method,
  ConsoleClient client,
  Credentials credentials,
  Uint8List payload,
  String region,
}) async {
  var headers = <String, String>{
    'X-Amz-Content-Sha256': sha256.convert(payload.toList()).toString()
  };
  if (credentials.sessionToken != null) {
    headers['X-Amz-Security-Token'] = credentials.sessionToken;
  }
  var getRequest = AwsRequestBuilder(
      method: method,
      body: payload.toList(),
      headers: headers,
      region: region,
      uri: Uri.parse(uri),
      credentials: credentials,
      httpClient: client,
      service: 's3');

  return getRequest.sendRequest();
}
