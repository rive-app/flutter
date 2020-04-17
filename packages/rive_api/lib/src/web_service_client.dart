import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart';

import 'package:local_data/local_data.dart';
import 'package:rive_api/src/rive_http/http_interface.dart';

import 'http_exception.dart';

/// A callback for status code occurences.
typedef void StatusCodeHandler(http.Response response);

/// Web Service class to help facilitate making requests that have some form
/// of state maintained in cookies.
class WebServiceClient {
  final Map<String, String> headers = {"content-type": "text/json"};
  final Map<String, String> cookies = {};
  final Map<int, List<StatusCodeHandler>> statusCodeHandlers = {};

  /// We use this timer to schedule saving cookies locally.
  Timer _persistTimer;

  /// Encrypter we use to read/write the local session storage.
  final Encrypter _encrypter;
  final LocalDataPlatform localDataPlatform;
  final String context;
  LocalData localData;

  WebServiceClient(this.context,
      [String key = '}Mk#33zm^PiiP9C2riMozVynojddVc6/'])
      : _encrypter = Encrypter(AES(Key.fromUtf8(key))),
        localDataPlatform = LocalDataPlatform.make();

  void addStatusCodeHandler(int code, StatusCodeHandler handler) {
    List<StatusCodeHandler> handlers = statusCodeHandlers[code];
    handlers ??= [];
    handlers.add(handler);
    statusCodeHandlers[code] = handlers;
  }

  bool removeStatusCodeHandler(int code, StatusCodeHandler handler) =>
      statusCodeHandlers[code]?.remove(handler) ?? false;

  void _processResponse(http.Response response) {
    // Update cookies.
    String allSetCookie = response.headers['set-cookie'];

    if (allSetCookie != null) {
      var setCookies = allSetCookie.split(',');

      var changed = false;
      for (final setCookie in setCookies) {
        if (_setCookiesFromString(setCookie)) {
          changed = true;
        }
      }

      if (changed) {
        _persistTimer?.cancel();
        _persistTimer = Timer(const Duration(seconds: 2), persist);
      }

      headers['cookie'] = _generateCookieHeader();
    }

    // Call status code handlers.
    statusCodeHandlers[response.statusCode]?.forEach((f) => f.call(response));
  }

  bool _setCookiesFromString(String cookieString) {
    var changed = false;
    var cookies = cookieString.split(';');
    for (final cookie in cookies) {
      if (_setCookie(cookie)) {
        changed = true;
      }
    }
    return changed;
  }

  void setCookie(String key, String value) {
    cookies[key] = value;
    headers['cookie'] = _generateCookieHeader();
  }

  Future<void> clearCookies() async {
    cookies.clear();
    headers['cookie'] = _generateCookieHeader();
    await persist();
  }

  bool _setCookie(String rawCookie) {
    if (rawCookie.isNotEmpty) {
      var keyValue = rawCookie.split('=');
      if (keyValue.length == 2) {
        var key = keyValue[0].trim();
        var value = keyValue[1];

        // ignore keys that aren't cookies
        if (key == 'path' || key == 'expires') return false;

        var lastValue = cookies[key];
        if (lastValue != value) {
          cookies[key] = value;
          return true;
        }
      }
    }
    return false;
  }

  String _generateCookieHeader() {
    StringBuffer cookie = StringBuffer();

    for (final key in cookies.keys) {
      if (cookie.isNotEmpty) cookie.write(';');
      cookie.write(key);
      cookie.write('=');
      cookie.write(cookies[key]);
    }
    return cookie.toString();
  }

  Future<http.Response> get(String url) async {
    try {
      final client = getClient();
      final response = await client.get(url, headers: headers);

      _processResponse(response);

      return response;
    } on Exception catch (error) {
      var errorString = error.toString();
      print('er \'$errorString\'');
      if (errorString.startsWith('XMLHttpRequest') ||
          errorString.startsWith('SocketException') ||
          errorString.startsWith('Unauthorised')) {
        throw HttpException(errorString, error);
      } else {
        rethrow;
      }
    }
  }

  Future<http.Response> post(String url,
      {dynamic body, Encoding encoding}) async {
    try {
      final client = getClient();
      var response = await client.post(url,
          body: body, headers: headers, encoding: encoding);

      _processResponse(response);
      return response;
    } on Exception catch (error) {
      //SocketException
      var errorString = error.toString();
      if (errorString.startsWith('XMLHttpRequest') ||
          errorString.startsWith('SocketException')) {
        throw HttpException(errorString, error);
      } else {
        rethrow;
      }
    }
  }

  Future<http.Response> put(String url,
      {dynamic body, Encoding encoding}) async {
    try {
      final client = getClient();
      var response = await client.put(url,
          body: body, headers: headers, encoding: encoding);

      _processResponse(response);
      return response;
    } on Exception catch (error) {
      //SocketException
      var errorString = error.toString();
      if (errorString.startsWith('XMLHttpRequest') ||
          errorString.startsWith('SocketException')) {
        throw HttpException(errorString, error);
      } else {
        rethrow;
      }
    }
  }

  Future<bool> initialize() async {
    await localDataPlatform.initialize();
    localData = LocalData.make(localDataPlatform, context);
    await localData.initialize();
    
    var contents = await localData.load('cookie');
    if (contents == null || contents.isEmpty) {
      return true;
    }

    var iv = IV.fromLength(16);
    var decrypted =
        _encrypter.decrypt(Encrypted(Uint8List.fromList(contents)), iv: iv);
    if (decrypted == null) {
      return false;
    }
    _setCookiesFromString(decrypted);
    headers['cookie'] = _generateCookieHeader();

    return true;
  }

  Future<void> persist() async {
    var data = _generateCookieHeader();
    if (data.isEmpty) {
      return localData.save('cookie', Uint8List(0));
    }
    var iv = IV.fromLength(16);
    var encrypted = _encrypter.encrypt(_generateCookieHeader(), iv: iv);
    await localData.save('cookie', encrypted.bytes);
  }
}
