import 'dart:async';

import 'package:rive_api/api.dart';
import 'package:rive_api/model.dart';
import 'package:rive_core/rive_file.dart';
import 'package:rxdart/streams.dart';
import 'package:rxdart/subjects.dart';
import 'package:rive_core/coop_importer.dart';

/// A temporary file that has no coop backing, for preview purposes.
class TempRiveFile extends RiveFile {
  TempRiveFile() : super(null, localDataPlatform: null);
}

/// Handles loading lists of revisions and changing the selected (for preview)
/// revision. It'll load the revision file and make a Core file that can be
/// displayed by hooking it up to a Stage.
class RevisionManager {
  final RevisionApi revisionApi;
  RevisionManager({RiveApi api, int fileId})
      : revisionApi = RevisionApi(
          api: api,
          fileId: fileId,
        ) {
    _selectedRevision.add(null);
    _selectRevision.stream.listen(_onSelectRevision);
    _loadList();
  }

  Future<void> _onSelectRevision(RevisionDM revision) async {
    _selectedRevision.add(revision);

    var bytes = await revisionApi.contents(revision);
    var file = TempRiveFile();
    var importer = CoopImporter(core: file);
    if (importer.import(bytes)) {
      _preview.add(file);
    }
  }

  final _list = BehaviorSubject<List<RevisionDM>>();
  ValueStream<List<RevisionDM>> get list => _list.stream;

  final _selectedRevision = BehaviorSubject<RevisionDM>();
  ValueStream<RevisionDM> get selectedRevision => _selectedRevision;
  final _selectRevision = StreamController<RevisionDM>();
  Sink<RevisionDM> get select => _selectRevision;

  final _preview = BehaviorSubject<TempRiveFile>();
  ValueStream<TempRiveFile> get preview => _preview.stream;

  Future<void> _loadList() async {
    var results = await revisionApi.list();
    _list.add(results);
  }

  void dispose() {
    _list.close();
    _selectedRevision.close();
    _selectRevision.close();
    _preview.close();
  }
}
