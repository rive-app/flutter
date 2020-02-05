import 'src/web_service_client.dart';
export 'src/http_exception.dart';

class RiveApi extends WebServiceClient {
  final String host = 'http://localhost:3000';
  //final String host = 'https://arkham.rive.app';
  RiveApi() : super('rive-api');
}
