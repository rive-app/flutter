import 'package:utilities/deserialize.dart';
import 'package:meta/meta.dart';
import 'owner.dart';

/// Data model for a logged-in user

class CDN extends Owner {
  const CDN({
    @required this.base,
    @required this.params,
  });
  final String base;
  final String params;

  factory CDN.fromData(Map<String, dynamic> data) => CDN(
        base: data.getString('base'),
        params: data.getString('params'),
      );

  @override
  String toString() => 'CDN($base, $params)';
}
