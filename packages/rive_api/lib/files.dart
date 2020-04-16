import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart';
import 'package:rive_api/api.dart';
import 'package:rive_api/models/cdn.dart';
import 'package:rive_api/models/file.dart';
import 'package:rive_api/folder.dart';
import 'package:rive_api/src/deserialize_helper.dart';

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
  Future<bool> fillTeamDetails(int teamOwnerId, Iterable<K> files) async {
    String ids =
        jsonEncode(files.map((file) => file.id).toList(growable: false));
    var response =
        await api.post(api.host + '/api/teams/$teamOwnerId/files', body: ids);
    return _parseDetails(files, response);
  }

  Future<bool> fillDetails(Iterable<K> files) async {
    String ids =
        jsonEncode(files.map((file) => file.id).toList(growable: false));
    var response = await api.post(api.host + '/api/my/files', body: ids);
    return _parseDetails(files, response);
  }

  bool _parseDetails(Iterable<K> files, Response response) {
    Map<int, K> lookup = <int, K>{};
    for (final file in files) {
      lookup[file.id] = file;
    }

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
        cdn = RiveCDN.fromData(cdnData);
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

    return _parseFolderFiles(response, cacheLocator);
  }

  Future<List<K>> teamFolderFiles(int teamOwnerId, RiveFileSortOption sort,
      {T folder, FileLocator<K> cacheLocator}) async {
    var response = await api.get(api.host +
        '/api/teams/$teamOwnerId/files/a-z/rive/' +
        (folder?.id ?? ''));
    return _parseFolderFiles(response, cacheLocator);
  }

  List<K> _parseFolderFiles(Response response, FileLocator<K> cacheLocator) {
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

  Future<FoldersResult<T>> teamFolders(int teamOwnerId) async {
    var response =
        await api.get(api.host + '/api/teams/${teamOwnerId}/folders');
    return _parseFoldersReponse(response);
  }

  /// Flat list of all the folders in the signed in user's hierarchy.
  Future<FoldersResult<T>> myFolders() async {
    var response = await api.get(api.host + '/api/my/files/folders');
    return _parseFoldersReponse(response);
  }

  FoldersResult<T> _parseFoldersReponse(Response response) {
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
    return _parseFileResponse(response);
  }

  Future<K> createTeamFile(
    int teamOwnerId, {
    T folder,
  }) async {
    String payload = json.encode({
      'data': {'fileName': 'New File'}
    });
    var response = await api.post(
        api.host + '/api/teams/${teamOwnerId}/folders/${folder.id}/new/rive/',
        body: payload);
    return _parseFileResponse(response);
  }

  K _parseFileResponse(Response response) {
    // Team response
    // {"file":{"id":1,"oid":40846,"name":"New File","route":"/a/null/files/rive/new-file","product":"rive"},"reroute":"/a/null/files/rive/new-file"}

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

  Future<T> createFolder(T folder) async {
    String payload =
        json.encode({'name': 'New Folder', 'order': 0, 'parent': folder.id});

    var response =
        await api.post(api.host + '/api/my/files/folder', body: payload);
    return _parseFolderResponse(response);
  }

  T _parseFolderResponse(Response response) {
    if (response.statusCode == 200) {
      var folderResponse = json.decode(response.body);
      return makeFolder(folderResponse);
    }
    return null;
  }

  Future<T> createTeamFolder(
    int teamOwnerId, {
    T folder,
  }) async {
    String payload = json.encode({
      'data': {'folderName': 'New Folder'}
    });
    var response = await api.post(
        api.host + '/api/teams/${teamOwnerId}/folders/' + (folder?.id ?? ''),
        body: payload);
    return _parseFolderResponse(response);
  }

  /// Find the socket server url to connect to for a specific file.
  Future<CoopConnectionInfo> establishCoop(int ownerId, int fileId) async {
    var response = await api.get(api.host + '/api/files/$ownerId/$fileId/coop');
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
