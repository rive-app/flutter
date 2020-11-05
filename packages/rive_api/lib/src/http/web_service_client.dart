import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:http/http.dart' as http;
import 'package:local_data/local_data.dart';
import 'package:rive_api/http.dart';

import 'http_exception.dart';

/// Status code classes
///
/// Informational 1xx, success 2xx, redirection 3xx, clientErrors 4xx,
/// serverErrors 5xx
enum StatusCodeClass {
  informational,
  success,
  redirection,
  clientErrors,
  serverErrors,
  unofficial
}

/// Returns the class for a status code
StatusCodeClass statusCodeClass(int statusCode) {
  switch (statusCode ~/ 100) {
    case 1:
      return StatusCodeClass.informational;
    case 2:
      return StatusCodeClass.success;
    case 3:
      return StatusCodeClass.redirection;
    case 4:
      return StatusCodeClass.clientErrors;
    case 5:
      return StatusCodeClass.serverErrors;
    default:
      return StatusCodeClass.unofficial;
  }
}

/// A callback for status code occurences.
typedef void StatusCodeHandler(http.Response response);

/// Web Service class to help facilitate making requests that have some form
/// of state maintained in cookies.
class WebServiceClient {
  final Map<String, String> cookies = {};

  final Map<String, String> _headers = {'content-type': 'text/json'};
  final Map<int, List<StatusCodeHandler>> _statusCodeHandlers = {};

  /// Optional list of acceptable status codes; if not returned, then
  /// the handler for unacceptable codes is run
  final Set<StatusCodeClass> _acceptableStatusCodes = <StatusCodeClass>{};
  StatusCodeHandler handleUnacceptableStatusCode;

  /// We use this timer to schedule saving cookies locally.
  Timer _persistTimer;

  /// Encrypter we use to read/write the local session storage.
  final Encrypter _encrypter;
  final LocalDataPlatform _localDataPlatform;
  final String _context;
  LocalData localData;

  WebServiceClient(this._context,
      [String key = '}Mk#33zm^PiiP9C2riMozVynojddVc6/'])
      : _encrypter = Encrypter(AES(Key.fromUtf8(key))),
        _localDataPlatform = LocalDataPlatform.make();

  void addStatusCodeHandler(int code, StatusCodeHandler handler) {
    List<StatusCodeHandler> handlers = _statusCodeHandlers[code];
    handlers ??= [];
    handlers.add(handler);
    _statusCodeHandlers[code] = handlers;
  }

  bool removeStatusCodeHandler(int code, StatusCodeHandler handler) =>
      _statusCodeHandlers[code]?.remove(handler) ?? false;

  /// Add acceptable status codes, and what to do if they aren't received
  void addAcceptableStatusCodes(
      List<StatusCodeClass> classes, StatusCodeHandler handler) {
    assert(classes != null && handler != null);
    _acceptableStatusCodes.addAll(classes);
    handleUnacceptableStatusCode = handler;
  }

  void _processResponse(http.Response res) {
    // Update cookies.
    String allSetCookie = res.headers['set-cookie'];

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

      _headers['cookie'] = _generateCookieHeader();
    }

    // Call status code handlers.
    _statusCodeHandlers[res.statusCode]?.forEach((f) => f.call(res));

    // Check the acceptable status codes
    if (_acceptableStatusCodes
        .every((c) => c != statusCodeClass(res.statusCode))) {
      handleUnacceptableStatusCode(res);
    }
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
    _headers['cookie'] = _generateCookieHeader();
    print('Setting cookies: $_headers');
  }

  Future<void> clearCookies() async {
    print('clear cookies');
    // We should only clear cookies and regenerate the cook header if there are
    // cookies; otherwise we're going to create a blank cookie header for the
    // web app, which lets the browser manage cookies for it. fixes #647
    if (cookies.isNotEmpty) {
      cookies.clear();
      _headers['cookie'] = _generateCookieHeader();
      await persist();
    }
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

      var completed = false;

      Future.delayed(const Duration(seconds: 1), () {
        if (!completed) {
          print('Getting $url took longer than a second');
        }
      });

      // final timer = Stopwatch()..start();
      final response = await client.get(url, headers: _headers);
      completed = true;

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

  /// Post may want binary data so we leave body as dynamic.
  Future<http.Response> post(String url,
      {dynamic body, Encoding encoding}) async {
    try {
      final client = getClient();
      print('posting to $url');
      var response = await client.post(url,
          body: body, headers: _headers, encoding: encoding);

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

  Future<http.Response> patch(String url,
      {dynamic body, Encoding encoding}) async {
    try {
      final client = getClient();
      print('patching to $url');
      var response = await client.patch(url,
          body: body, headers: _headers, encoding: encoding);

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
      print('putting $url');
      var response = await client.put(url,
          body: body, headers: _headers, encoding: encoding);

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

  /// We define body as a String because the underlying http client doesn't
  /// explicitly allow setting a body on the delete request. So we create a
  /// custom http request with a delete verb in order to provide the body. In
  /// this case the API only allows a String for the body.
  Future<http.Response> delete(String url,
      {String body = '', Encoding encoding}) async {
    try {
      print('deleting $url');
      // TODO: Matt, can we do 'injection'? would love to capture how many times
      // the base request stuff gets called.
      final request = http.Request('delete', Uri.parse(url));
      request.body = body;
      request.headers.addAll(_headers);
      // request.encoding = Encoding;
      var stream = await getClient().send(request);
      var response = await http.Response.fromStream(stream);
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
    await _localDataPlatform.initialize();
    localData = LocalData.make(_localDataPlatform, _context);
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
    _headers['cookie'] = _generateCookieHeader();

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
