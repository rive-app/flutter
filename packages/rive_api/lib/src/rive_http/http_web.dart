import 'package:http/browser_client.dart';
import 'package:http/http.dart';

Client getClientImplementation() {
  final client = BrowserClient();
  client.withCredentials = true;
  return client;
}
