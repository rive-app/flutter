/// API calls for the logged-in user

import 'dart:convert';

import 'package:rive_api/api.dart';
import 'package:rive_api/data_model.dart';

import 'package:utilities/deserialize.dart';

/// API for accessing user announcements
class AnnouncementsApi {
  AnnouncementsApi([RiveApi api]) : api = api ?? RiveApi();
  final RiveApi api;

  /// GET /api/announcements
  /// Returns the current announcements for a user
  Future<List<AnnouncementDM>> get announcements async {
    final res = await api.get('${api.host}/api/announcements');

    final data = json.decodeMap(res.body);
    // Need to decode a second time as we have json within json

    dynamic decodedData = data['data'];
    if (decodedData is String) {
      decodedData = json.decode(decodedData as String);
    }

    assert(decodedData is List,
        'at this point decodedData must be a list of js objects');

    // Adding in a test team announcement temporarily
    final announcements = <AnnouncementDM>[]..addAll(
        AnnouncementDM.fromDataList(
          (decodedData as List).cast<Map<String, dynamic>>(),
        ),
      );
    return announcements;
  }

  /// POST /api/announcements/read
  /// Mark al announcements as read
  Future<void> markAnnouncementsRead() =>
      api.post('${api.host}/api/announcements/read');
}
