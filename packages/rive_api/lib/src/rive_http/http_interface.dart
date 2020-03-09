import 'package:http/http.dart';
import 'http_app.dart' if (dart.library.html) 'http_web.dart';

typedef ClientTypeDef = Client Function();

ClientTypeDef getClient = getClientImplementation;
