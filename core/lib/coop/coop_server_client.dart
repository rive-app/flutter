import 'dart:typed_data';

import 'change.dart';
import 'coop_isolate.dart';
import 'coop_reader.dart';
import 'coop_writer.dart';

class CoopServerClient extends CoopReader {
  CoopWriter _writer;
  final int id;
  // final HttpRequest request;
  final CoopIsolateProcess context;

  // Do these need to be persisted somewhere? If a user stores local changes
  // against an old id and the server is restarted/the user reconnects, they
  // could send up old ids that still need to be remapped. Consider storing
  // these somewhere where they can be retrieved during authentication of the
  // session.
  final Map<int, int> changedIds = {};

  CoopWriter get writer => _writer;

  void receiveData(dynamic data) {
    if (data is Uint8List) {
      read(data);
    }
  }

  CoopServerClient(this.context, this.id) {
    _writer = CoopWriter(write);

    _writer.writeHello();

    // socket.listen(
    //   (dynamic data) {
    //     if (data is Uint8List) {
    //       read(data);
    //     }
    //   },
    //   onDone: () => context.remove(this),
    //   onError: (dynamic err) => print('[!]Error -- ${err.toString()}'),
    //   cancelOnError: true,
    // );
  }

  void write(Uint8List buffer) {
    // assert(_isConnected);
    // socket.add(buffer);
    context.write(this, buffer);
  }

  @override
  Future<void> recvChange(ChangeSet changes) async {
    print("CHANGES ${changes.id} ${changes.changes.length}");
    print("SERVER GOT CHANGES $changes");
    if (context.attemptChange(this, changes)) {
      _writer.writeAccept(changes.id, 0);

      // this should acctually be done by the attempt change as it needs to
      // modify the data

      // context.propagateChanges(this, changes);
      // propagate changes to everyone else... need to write it to the context,
      // and it needs to propagate to other clients
    }
  }

  @override
  Future<void> recvGoodbye() {
    throw UnimplementedError();
  }

  @override
  Future<void> recvHand(int desiredSession, String fileId, String token,
      int lastServerChangeId) async {
    var session = await context.login(token, desiredSession);
    if (session == null) {
      _writer.writeGoodbye();
    } else {
      print("GOT THE HAND $session $fileId $token $lastServerChangeId");
      // Get session from user
      _writer.writeShake(session.id, session.changeId);
    }
  }

  @override
  Future<void> recvHello() {
    throw UnsupportedError("Server should never receive hello.");
  }

  @override
  Future<void> recvShake(int session, int lastSeenChangeId) {
    throw UnsupportedError("Server should never receive shake.");
  }

  @override
  Future<void> recvAccept(int changeId, int serverChangeId) {
    throw UnsupportedError("Server should never receive accept.");
  }

  @override
  Future<void> recvReject(int changeId) {
    throw UnsupportedError("Server should never receive reject.");
  }

  @override
  Future<void> recvChangeId(int from, int to) {
    throw UnsupportedError("Server should never receive change id.");
  }
}
