import 'package:rive_api/src/data_model/announcement.dart';

/// Base notification class that has a factory that will construct
/// the appropriate concrete notification
class Announcement {
  const Announcement(
      {this.id, this.title, this.body, this.validFrom, this.validTo});
  final int id;
  final String title;
  final String body;
  final DateTime validFrom;
  final DateTime validTo;

  static List<Announcement> fromDMList(List<AnnouncementDM> announcements) =>
      announcements
          .map((announcement) => Announcement.fromDM(announcement))
          .toList();

  factory Announcement.fromDM(AnnouncementDM announcement) {
    return Announcement(
      id: announcement.id,
      title: announcement.title,
      body: announcement.body,
      validFrom: announcement.validFrom,
      validTo: announcement.validTo,
    );
  }
}
