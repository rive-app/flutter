@JS()
library browser;

import 'package:js/js.dart';
import 'package:meta/meta.dart';

@JS('window.navigator.standalone')
external bool get _standalone;

/// The window.navigator.standalone DOM property.
bool get standalone => _standalone ?? false;

@visibleForTesting
@JS('window.navigator.standalone')
external set standalone(bool enabled);

@JS('window.innerHeight')
external int get _height;

/// The window.height() js call
int get height => _height;

@JS('window.innerWidth')
external int get _width;

/// The window.width() js call
int get width => _width;
