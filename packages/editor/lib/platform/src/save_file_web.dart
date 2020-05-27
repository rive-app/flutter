import 'dart:html' as html;
import 'dart:js' as js;

import 'dart:typed_data';

Future<bool> saveFile(String name, Uint8List bytes) async {
  js.context.callMethod(
    "saveAs",
    <dynamic>[
      html.Blob(
        <dynamic>[bytes],
      ),
      name,
    ],
  );
  return true;
}
