import 'package:http/browser_client.dart';
import 'package:http/http.dart';

Client getClientImplementation() => BrowserClient()..withCredentials = true;
