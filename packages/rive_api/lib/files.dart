import 'dart:convert';
import 'dart:core';

import 'api.dart';
import 'cdn.dart';
import 'file.dart';
import 'folder.dart';
import 'src/deserialize_helper.dart';

/// Result returned by getting a list of folders and the sort options for the
/// file contents.
class FoldersResult<T extends RiveApiFolder> {
  final List<T> folders;
  final List<RiveFileSortOption> sortOptions;
  final List<T> root;

  FoldersResult({
    this.folders,
    this.sortOptions,
    this.root,
  });
}

typedef FileLocator<T extends RiveApiFile> = T Function(int id);

/// Api for accessing the signed in users folders and files.
abstract class RiveFilesApi<T extends RiveApiFolder, K extends RiveApiFile> {
  final RiveApi api;
  RiveFilesApi(this.api);

  /// Fill in the details for the list of provided files (name, preview, etc).
  Future<bool> fillDetails(Iterable<K> files) async {
    Map<int, K> lookup = <int, K>{};
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
            var id = fileData.getInt('id');

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

  /// Gets a list of the files that belong to a folder. Because this can be
  /// long, the API optimizes this by returning a simple list of ids. This
  /// allows the UI to quickly display a view that occupies the space necessary
  /// for each file, but then fills in the file details with a second request.
  ///
  /// That file list for that second request to [fillDetails] should be built up
  /// by debouncing a list of files that are in view. This can be computed by
  /// tracking when a file item widget is attached/unattached to the flutter
  /// widget tree.
  ///
  /// You can provide a [cacheLocator] to re-use previously loaded files (helps
  /// prevent flickering in your UI layer).
  Future<List<K>> folderFiles(RiveFileSortOption sort,
      {T folder, FileLocator<K> cacheLocator}) async {
    var response =
        await api.get(api.host + sort.route + 'rive/' + (folder?.id ?? ''));

    if (response.statusCode == 200) {
      List data;
      try {
        data = json.decode(response.body) as List;
      } on FormatException catch (_) {
        return null;
      }
      List<K> results = [];
      if (data != null) {
        for (final dynamic value in data) {
          if (value == null || value is! int) {
            continue;
          }
          var id = value as int;
          results.add(cacheLocator?.call(id) ?? makeFile(id));
        }
      }
      return results;
    }
    return null;
  }

  K makeFile(int id);

  T makeFolder(Map<String, dynamic> data);

  /// Flat list of all the folders in the signed in user's hierarchy.
  Future<FoldersResult<T>> myFolders() async {
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
      List<T> results = [];
      List<T> root = [];
      T allFilesFolder;
      if (folders is List) {
        for (final dynamic value in folders) {
          if (value is Map<String, dynamic>) {
            results.add(makeFolder(value));
          }
        }

        allFilesFolder = results.firstWhere((folder) => folder.id == '1');

        for (final T folder in results) {
          if (!folder.findParent(results, allFilesFolder)) {
            root.add(folder);
          }
        }
      }
      return FoldersResult<T>(
        folders: results,
        sortOptions: sortOptions,
        root: root,
      );
    }
    return null;
  }

  // /api/my/files/:product/create/:folder_id?
  Future<K> createFile({T folder}) async {
    var response = await api
        .post(api.host + '/api/my/files/rive/create/' + (folder?.id ?? ''));
    if (response.statusCode != 200) {
      return null;
    }
    Map<String, dynamic> data;
    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } on FormatException catch (_) {
      return null;
    }

    dynamic fileData = data['file'];
    if (fileData is Map<String, dynamic>) {
      return makeFile(fileData.getInt("id"));
    }
    return null;
  }

  /// Find the socket server url to connect to for a specific file.
  Future<CoopConnectionInfo> establishCoop(K riveFile) async {
    var response = await api
        .get(api.host + '/api/files/${riveFile.ownerId}/${riveFile.id}/coop');
    if (response.statusCode != 200) {
      return null;
    }

    Map<String, dynamic> data;
    try {
      data = json.decode(response.body) as Map<String, dynamic>;
    } on FormatException catch (_) {
      return null;
    }

    return CoopConnectionInfo(data.getString('socketHost'));
  }
}

class CoopConnectionInfo {
  final String socketHost;

  CoopConnectionInfo(this.socketHost);
}

class RiveFileSortOption {
  final String name;
  final String route;

  RiveFileSortOption(Map<String, dynamic> data)
      : name = data["name"]?.toString(),
        route = data["route"]?.toString();
}
