import 'package:utilities/deserialize.dart';

class AnnouncementDM {
  const AnnouncementDM(
      {this.id, this.title, this.body, this.validFrom, this.validTo});
  final int id;
  final String title;
  final String body;
  final DateTime validFrom;
  final DateTime validTo;

  /// Builds a list of notifications from json data
  static List<AnnouncementDM> fromDataList(
          List<Map<String, dynamic>> dataList) =>
      dataList
          .map<AnnouncementDM>((data) => AnnouncementDM.fromData(data))
          .toList(growable: false);

  /// Builds the right type of notification based on json data
  factory AnnouncementDM.fromData(Map<String, dynamic> data) {
    return AnnouncementDM(
      id: data.getInt('id'),
      title: data.getString('title'),
      body: data.getString('body'),
      validFrom: data.getDateTime('validFrom'),
      validTo: data.getDateTime('validTo'),
    );
  }
}
