/// Fetch the latest changelog
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:rive_api/src/deserialize_helper.dart';

/// Data class for changelogs
class Changelog {
  Changelog({this.version, this.items});
  final String version;
  final List<ChangelogItem> items;

  factory Changelog.fromData(Map<String, dynamic> data) => Changelog(
        version: data.getString('version'),
        items: ChangelogItem.fromDataList(data.getList('items')),
      );

  /// Returns a list of changelogs from a JSON document
  static List<Changelog> fromDataList(List<dynamic> dataList) => dataList
      .map<Changelog>(
        (data) => Changelog.fromData(data),
      )
      .toList(growable: false);

  @override
  String toString() => 'ChangelogItem($version, @$items)';
}

class ChangelogItem {
  ChangelogItem({this.title, this.description});
  final String title;
  final String description;

  factory ChangelogItem.fromData(Map<String, dynamic> data) => ChangelogItem(
      title: data.getString('title'),
      description: data.getString('description'));

  /// Returns a list of changelog items from a JSON document
  static List<ChangelogItem> fromDataList(List<dynamic> dataList) => dataList
      .map<ChangelogItem>(
        (data) => ChangelogItem.fromData(data),
      )
      .toList(growable: false);

  @override
  String toString() => 'ChangelogItem($title, @$description)';
}

/// Fetches the changelog from a URL
Future<List<Changelog>> fetchChangelogs() async {
  final res =
      await http.get('https://cdn.rive.app/changelogs/stryker/changelog.json');

  if (res.statusCode == 200) {
    return Changelog.fromDataList(json.decode(res.body));
  }
  throw Exception('Unable to fetch changelog');
}
