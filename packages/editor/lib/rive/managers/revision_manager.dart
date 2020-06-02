import 'dart:async';

import 'package:rive_api/api.dart';
import 'package:rive_api/model.dart';
import 'package:rxdart/streams.dart';
import 'package:rxdart/subjects.dart';

class RevisionManager {
  final RevisionApi revisionApi;
  RevisionManager({RiveApi api, int ownerId, int fileId})
      : revisionApi = RevisionApi(
          api: api,
          fileId: fileId,
          ownerId: ownerId,
        ) {
    _selectedRevision.add(null);
    _selectRevision.stream.listen(_onSelectRevision);
    _loadList();
  }

  void _onSelectRevision(RevisionDM revision) {
    _selectedRevision.add(revision);
  }

  final _list = BehaviorSubject<List<RevisionDM>>();
  ValueStream<List<RevisionDM>> get list => _list.stream;

  final _selectedRevision = BehaviorSubject<RevisionDM>();
  ValueStream<RevisionDM> get selectedRevision => _selectedRevision;
  final _selectRevision = StreamController<RevisionDM>();
  Sink<RevisionDM> get select => _selectRevision;

  Future<void> _loadList() async {
    var results = await revisionApi.list();
    _list.add(results);
  }

  void dispose() {
    _list.close();
    _selectedRevision.close();
    _selectRevision.close();
  }
}
