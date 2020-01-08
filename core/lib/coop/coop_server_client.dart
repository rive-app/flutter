import 'dart:io';
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
    _writer.writeAccept(changes.id, 0);
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
}
