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
  final int clientId;
  // final HttpRequest request;
  final CoopIsolateProcess context;

  CoopWriter get writer => _writer;

  void receiveData(dynamic data) {
    if (data is Uint8List) {
      read(data);
    }
  }

  CoopServerClient(this.context, this.id, this.userOwnerId, this.clientId) {
    _writer = CoopWriter(write);

    _writer.writeHello(clientId);
  }

  void write(Uint8List buffer) {
    print("WRITING COMMAND ${buffer[0]}");
    context.write(this, buffer);
  }

  @override
  void recvChange(ChangeSet changes) {
    if (context.attemptChange(this, changes)) {
      _writer.writeAccept(changes.id);
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

    final initialChanges = context.buildFileChangeSet();
    if (initialChanges != null) {
      _writer.writeChanges(initialChanges);
    }
    _writer.writeReady();
  }

  @override
  Future<void> recvWipe() {
    throw UnsupportedError("Server should never receive wipe.");
  }

  @override
  Future<void> recvHello(int clientId) {
    throw UnsupportedError("Server should never receive hello.");
  }

  @override
  Future<void> recvAccept(int changeId) {
    throw UnsupportedError("Server should never receive accept.");
  }

  @override
  Future<void> recvReject(int changeId) {
    throw UnsupportedError("Server should never receive reject.");
  }

  @override
  Future<void> recvIds(int min, int max) {
    throw UnsupportedError("Server should never receive ids.");
  }

  @override
  Future<void> recvRequestIds(int amount) async {
    IdRange range = context.allocateIds(amount);
    debounce(context.persist, duration: const Duration(seconds: 2));
    writer.writeIds(range.min, range.max);
  }

  @override
  Future<void> recvReady() {
    throw UnsupportedError("Server should never receive ready.");
  }
}

class IdRange {
  final int min;
  final int max;

  IdRange(this.min, this.max);
}
