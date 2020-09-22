import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'dart:typed_data';

const port = 3003;

Future<void> main() async {
  final server = await HttpServer.bind('0.0.0.0', port);

  print('Listening on port $port');

  await for (final req in server) {
    print('Request received');
    await _handleRequest(req);
    await req.response.close();
  }
}

Future<void> _handleRequest(HttpRequest req) async {
  final uriStr = req.uri.toString();
  // Handle simple requests
  switch (uriStr) {
    case '/coop/register':
      print('Register request');
      return;
    case '/coop/deregister':
      print('Deregister request');
      return;
  }
  // Handle heartbeat request
  // can contain query parameters
  if (req.method == 'GET' && uriStr.contains('heartbeat')) {
    print('Heartbeat');
    if (req.uri.queryParameters.isNotEmpty) {
      req.uri.queryParameters.forEach((k, v) => print('Param: $k: $v'));
    } else {
      print('No params');
    }
    return;
  }

  // Handle save request
  // http.post('$host/revise/$ownerId/$fileId', body: data)
  if (req.method == 'POST' && uriStr.contains('revise')) {
    print('Save request, returning dummy data');

    // Parse ownerid and fileid
    final tokens = uriStr.split('/');
    final fileId = tokens.last;
    final ownerId = tokens[tokens.length - 2];

    final buffer = <int>[];
    final completer = Completer<void>();
    final subscription = req.listen((data) {
      buffer.addAll(data.toList());
    }, onError: () {
      print('Error saving data for $ownerId-$fileId');
      return;
    }, onDone: () {
      final bytes = Uint8List.fromList(buffer);

      final resData = json.encode({
        'key': '$ownerId-$fileId',
        'revision_id': 0,
        'size': 0,
      });
      req.response.add(resData.codeUnits);
      completer.complete();
    });
    await completer.future;
    await subscription.cancel();
    return;
  }

  // Handle load request
  // http.get('$host/revision/$ownerId/$fileId')
  if (req.method == 'GET' && uriStr.contains('revision')) {
    print('Load request, returning zero bytes');
    req.response.write('');
    return;
  }
  // Handle restore
  // http.post('$host/revision/$ownerId/$fileId/$revisionId')
  if (req.method == 'POST' && uriStr.contains('revision')) {
    print('Restore revision request, returning zero bytes');
    req.response.write('');
    return;
  }
  // Handle store changeset
  //http.post(
  // '$host/changeset/${file.ownerId}/${file.fileId}/'
  // '${serverChangeId - CoopCommand.minChangeId}',
  // headers: headers,
  // body: writer.uint8Buffer)
  if (req.method == 'POST' && uriStr.contains('changeset')) {
    print('Store changeset request, returning zero bytes');

    // Read the headers
    // 'X-rive-owner-id'
    // 'X-rive-accepted' {'true' : 'false'}
    final ownerId = req.headers.value('X-rive-owner-id');
    final accepted = req.headers.value('X-rive-accepted');

    // Parse ownerid and fileid
    final tokens = uriStr.split('/');
    final serverChangeId = tokens.last;
    final fileId = tokens[tokens.length - 2];
    final fileOwnerId = tokens[tokens.length - 3];

    final buffer = <int>[];
    final completer = Completer<void>();
    final subscription = req.listen((data) {
      buffer.addAll(data.toList());
    }, onError: () {
      print('Error saving data for $ownerId-$fileId');
      return;
    }, onDone: () {
      final changeSetBytes = Uint8List.fromList(buffer);
      completer.complete();
    });
    await completer.future;
    await subscription.cancel();
    return;
  }
}
