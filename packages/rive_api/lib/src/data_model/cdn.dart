import 'package:utilities/deserialize.dart';
import 'package:meta/meta.dart';

/// Data model for a logged-in user

class CdnDM {
  const CdnDM({
    @required this.base,
    @required this.params,
  });
  final String base;
  final String params;

  factory CdnDM.fromData(Map<String, dynamic> data) => CdnDM(
        base: data.getString('base'),
        params: data.getString('params'),
      );

  static Map<String, CdnDM> fromDataMap(Map<String, dynamic> data) {
    return data.map<String, CdnDM>((key, dynamic value) =>
        MapEntry(key, CdnDM.fromData(value as Map<String, dynamic>)));
  }

  @override
  String toString() => 'CdnDM($base, $params)';
}
