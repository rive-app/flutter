import 'dart:convert';

import 'api.dart';
import 'file.dart';
import 'folder.dart';
import 'cdn.dart';
import 'src/deserialize_helper.dart';

class RiveFileSortOption {
  final String name;
  final String route;

  RiveFileSortOption(Map<String, dynamic> data)
      : name = data["name"]?.toString(),
        route = data["route"]?.toString();
}

/// Result returned by getting a list of folders and the sort options for the
/// file contents.
class FoldersResult {
  final List<RiveFolder> folders;
  final List<RiveFileSortOption> sortOptions;

  FoldersResult({
    this.folders,
    this.sortOptions,
  });
}

/// Api for accessing the signed in users folders and files.
class RiveFiles {
  final RiveApi api;
  RiveFiles(this.api);

  /// Flat list of all the folders in the signed in user's hierarchy.
  Future<FoldersResult> myFolders() async {
    var response = await api.get(api.host + '/api/my/files/folders');
    if (response.statusCode == 200) {
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } on FormatException catch (_) {
        return null;
      }
      dynamic sort = data['sortOptions'];
      List<RiveFileSortOption> sortOptions = [];
      if (sort is List) {
        for (final dynamic value in sort) {
          if (value is Map<String, dynamic>) {
            sortOptions.add(RiveFileSortOption(value));
          }
        }
      }

      dynamic folders = data['folders'];
      List<RiveFolder> results = [];
      if (folders is List) {
        for (final dynamic value in folders) {
          if (value is Map<String, dynamic>) {
            results.add(RiveFolder(value));
          }
        }
        for (final RiveFolder result in results) {
          result.findParent(results);
        }
      }
      return FoldersResult(folders: results, sortOptions: sortOptions);
    }
    return null;
  }

  /// Gets a list of the files that belong to a folder. Because this can be
  /// long, the API optimizes this by returning a simple list of ids. This
  /// allows the UI to quickly display a view that occupies the space necessary
  /// for each file, but then fills in the file details with a second request.
  ///
  /// That file list for that second request to [fillDetails] should be built up
  /// by debouncing a list of files that are in view. This can be computed by
  /// tracking when a file item widget is attached/unattached to the flutter
  /// widget tree.
  Future<List<RiveFile>> folderFiles(RiveFileSortOption sort,
      [RiveFolder folder]) async {
    var response =
        await api.get(api.host + sort.route + 'flare/' + (folder?.id ?? ''));

    if (response.statusCode == 200) {
      List data;
      try {
        data = json.decode(response.body) as List;
      } on FormatException catch (_) {
        return null;
      }
      List<RiveFile> results = [];
      if (data != null) {
        for (final dynamic value in data) {
          if (value == null) {
            continue;
          }
          results.add(RiveFile(value.toString()));
        }
      }
      return results;
    }
    return null;
  }

  /// Fill in the details for the list of provided files (name, preview, etc).
  Future<bool> fillDetails(Iterable<RiveFile> files) async {
    Map<String, RiveFile> lookup = {};
    for (final file in files) {
      lookup[file.id] = file;
    }

    String ids =
        jsonEncode(files.map((file) => file.id).toList(growable: false));
    var response = await api.post(api.host + '/api/my/files', body: ids);

    if (response.statusCode == 200) {
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>;
      } on FormatException catch (_) {
        return null;
      }

      RiveCDN cdn;
      dynamic cdnData = data["cdn"];
      if (cdnData is Map<String, dynamic>) {
        cdn = RiveCDN(cdnData);
      }
      dynamic filesData = data["files"];
      if (filesData is List) {
        for (final dynamic fileData in filesData) {
          if (fileData is Map<String, dynamic>) {
            var id = fileData["id"]?.toString();

            var file = lookup[id];
            if (file == null) {
              continue;
            }
            file.deserialize(cdn, fileData);
          }
        }
      }
      return true;
    }
    return false;
  }
}
