import 'src/web_service_client.dart';

class RiveApi extends WebServiceClient {
  final String host = 'http://localhost:3000';
  // final String host = 'https://rive.app';
  RiveApi() : super('rive-api');
}
