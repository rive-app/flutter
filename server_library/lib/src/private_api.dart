import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ValidationResult {
  final int userId;
  final int ownerId;

  ValidationResult(this.userId, this.ownerId);
}

class SaveResult {
  final String key;
  final int revisionId;
  final int size;

  SaveResult(this.key, this.revisionId, this.size);
}

class PrivateApi {
  final String host =
      Platform.environment['PRIVATE_API'] ?? 'http://localhost:3003';

  Future<ValidationResult> validate(
      int ownerId, int fileId, String token) async {
    try {
      var response = await http.get('$host/validate/$ownerId/$fileId/$token');
      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          data = json.decode(response.body) as Map<String, dynamic>;
        } on FormatException catch (_) {
          return null;
        }

        return ValidationResult(
          data['userId'] is int ? data['userId'] as int : 0,
          data['ownerId'] is int ? data['ownerId'] as int : 0,
        );
      }
      return null;
    } on Exception catch (_) {
      return null;
    }
  }

  Future<SaveResult> save(int ownerId, int fileId, Uint8List data) async {
    try {
      var response =
          await http.post('$host/revise/$ownerId/$fileId', body: data);
      if (response.statusCode == 200) {
        Map<String, dynamic> data;
        try {
          data = json.decode(response.body) as Map<String, dynamic>;
        } on FormatException catch (_) {
          return null;
        }

        return SaveResult(
          data['key'] is String ? data['key'] as String : null,
          data['revision_id'] is int ? data['revision_id'] as int : 0,
          data['size'] is int ? data['size'] as int : 0,
        );
      }
      return null;
    } on Exception catch (_) {
      return null;
    }
  }

  Future<Uint8List> load(int ownerId, int fileId) async {
    try {
      var response = await http.get('$host/revision/$ownerId/$fileId');
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } on Exception catch (_) {
      return null;
    }
  }
}
