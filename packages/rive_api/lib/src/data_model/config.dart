import 'package:utilities/deserialize.dart';

class ConfigDM {
  const ConfigDM({this.websocketUrl});

  final String websocketUrl;

  factory ConfigDM.fromData(Map<String, dynamic> data) => ConfigDM(
        websocketUrl: data.getString('websocket_url'),
      );
}
