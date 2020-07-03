import 'package:rive_api/data_model.dart';

class Config {
  const Config({this.websocketUrl});

  final String websocketUrl;

  factory Config.fromDM(ConfigDM configDM) =>
      Config(websocketUrl: configDM.websocketUrl);
}
