import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

Future<Uint8List> userFile(List<String> extensions) async {
  final uploadInput = html.FileUploadInputElement()
    ..accept = extensions.map((ext) => '.$ext').join(',')
    ..click();

  final completer = Completer<List<html.File>>();

  uploadInput.onChange.listen((e) {
    completer.complete(uploadInput.files);
  });
  final files = await completer.future;
  if (files.isEmpty) {
    return null;
  }

  var readCompleter = Completer<Uint8List>();
  var reader = html.FileReader();

  reader.onLoadEnd.listen((e) {
    readCompleter.complete(reader.result as Uint8List);
  });

  reader.onError.listen((fileEvent) {
    readCompleter.completeError(fileEvent);
  });

  reader.readAsArrayBuffer(files.first);
  return readCompleter.future;
}
