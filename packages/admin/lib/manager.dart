import 'dart:async';
import 'dart:convert';

import 'package:rive_api/api.dart';
import 'package:rive_api/auth.dart';
import 'package:rive_api/data_model.dart';
import 'package:rive_api/model.dart';
import 'package:rive_api/models/user.dart';
import 'package:rxdart/rxdart.dart';

class AdminManager {
  static final AdminManager instance = AdminManager._();

  final api = RiveApi();
  RiveAuth _auth;

  final _user = BehaviorSubject<RiveUser>();
  Stream<RiveUser> get user => _user.stream;

  final _ready = BehaviorSubject<bool>();
  Stream<bool> get ready => _ready.stream;

  AdminManager._() {
    initialize();
  }

  Future<bool> initialize() async {
    var ready = await api.initialize();
    if (ready) {
      _ready.add(ready);
      _auth = RiveAuth(api);
      _updateMe();
      return true;
    }

    return false;
  }

  Future<void> _updateMe() async => _user.add(await _auth.whoami());

  Future<AuthResponse> login(String username, String password) async {
    var response = await _auth.login(username, password);
    if (!response.isError) {
      _updateMe();
    }
    return response;
  }

  Future<bool> signout() async {
    var result = await _auth.signout();
    _updateMe();
    return result;
  }

  Future<bool> impersonate(String username) async {
    var response = await api.get(api.host + '/impersonate/$username');
    if (response.statusCode == 200) {
      _updateMe();
      return true;
    }
    return false;
  }

  Future<bool> invite(String email) async {
    var response = await api.get(api.host + '/invite/$email');
    if (response.statusCode == 200) {
      return true;
    }
    return false;
  }

  Future<dynamic> listTeams() async {
    var response = await api.get(api.host + '/api/admin/teams');
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    return false;
  }

  Future<dynamic> listUsers() async {
    var response = await api.get(api.host + '/api/admin/users');
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    return false;
  }

  Future<dynamic> deleteUser(int ownerId) async {
    var response = await api.delete(api.host + '/api/admin/users/$ownerId');
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    return false;
  }

  Future<dynamic> listCharges() async {
    var response = await api.get(api.host + '/api/admin/charges');
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    return false;
  }

  Future<dynamic> listTransactions() async {
    var response = await api.get(api.host + '/api/admin/transactions');
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    }
    return false;
  }

  Future<dynamic> chargeTeam(int ownerId) async {
    var response = await api.post(api.host + '/api/admin/charges/$ownerId');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return false;
  }

  Future<dynamic> reissueBillAndEmail(int ownerId, int chargeId) async {
    var response = await api
        .post(api.host + '/api/admin/charges/$ownerId/notify/$chargeId');
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return false;
  }

  Future<dynamic> createTransaction(
      {int ownerId,
      String unitCode,
      int unitCount,
      int unitCost,
      String headline,
      String serviceTime,
      String detail}) async {
    String payload = jsonEncode({
      "data": {
        "unitCode": unitCode,
        "unitCount": unitCount,
        "unitCost": unitCost,
        "headline": headline,
        "serviceTime": serviceTime,
        "detail": detail,
      }
    });
    var response = await api.post(api.host + '/api/admin/transactions/$ownerId',
        body: payload);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return false;
  }

  Future<dynamic> addAnnouncement({
    String title,
    String body,
    String validFrom,
    String validTo,
  }) async {
    String payload = jsonEncode({
      'data': {
        'title': title,
        'body': body,
        'validFrom': validFrom,
        'validTo': validTo,
      }
    });
    var response =
        await api.post(api.host + '/api/announcements', body: payload);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return false;
  }

  Future<List<Announcement>> getAnnouncements() async {
    var response = await api.get(api.host + '/api/announcements');
    if (response.statusCode == 200) {
      var data = (json.decode(response.body)['data'] as List)
          .cast<Map<String, dynamic>>();

      return Announcement.fromDMList(AnnouncementDM.fromDataList(data));
    }
    return [];
  }

  Future<void> cancelAnnoucement(int annoucementId) async {
    await api.delete(api.host + '/api/announcements/$annoucementId');
  }
}
