import 'package:utilities/deserialize.dart';

class RiveCDN {
  final String base;
  final String params;

  const RiveCDN({this.base, this.params});

  factory RiveCDN.fromData(Map<String, dynamic> data) => RiveCDN(
        base: data.getString('base'),
        params: data.getString('params'),
      );

  @override
  String toString() => 'RiveUser($base, $params)';
}
