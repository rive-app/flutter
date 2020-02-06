import 'dart:typed_data';
import '../debounce.dart';
import 'change.dart';
import 'coop_isolate.dart';
import 'coop_reader.dart';
import 'coop_writer.dart';

class CoopServerClient extends CoopReader {
  CoopWriter _writer;
  final int userOwnerId;
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

  CoopServerClient(this.context, this.id, this.userOwnerId) {
    _writer = CoopWriter(write);

    _writer.writeHello();
  }

  void write(Uint8List buffer) {
    print("WRITING COMMAND ${buffer[0]}");
    context.write(this, buffer);
  }

  @override
  void recvChange(ChangeSet changes) {
    int serverChangeId = context.attemptChange(this, changes);
    if (serverChangeId != 0) {
      _writer.writeAccept(changes.id, serverChangeId);
      debounce(context.persist, duration: const Duration(seconds: 2));
    } else {
      _writer.writeReject(changes.id);
    }
  }

  @override
  Future<void> recvGoodbye() {
    throw UnsupportedError("Server should never receive goodbye.");
  }

  @override
  Future<void> recvSync(List<ChangeSet> changes) async {
    print("got sync!");
    // Apply offline changes.
    if (changes.isNotEmpty) {
      for (final change in changes) {
        print("sync attempt change!");
        context.attemptChange(this, change);
      }
      debounce(context.persist, duration: const Duration(seconds: 2));
    }
    print("start the wipe!");

    _writer.writeWipe();

    _writer.writeChanges(context.initialChanges());

    _writer.writeReady();
  }

  @override
  Future<void> recvWipe() {
    throw UnsupportedError("Server should never receive wipe.");
  }

  @override
  Future<void> recvHello() {
    throw UnsupportedError("Server should never receive hello.");
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

  @override
  Future<void> recvReady() {
    throw UnsupportedError("Server should never receive ready.");
  }
}
