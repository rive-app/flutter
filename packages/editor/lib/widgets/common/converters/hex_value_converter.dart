import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Convert HSVColor to an editable hex value.
class HexValueConverter extends InputValueConverter<HSVColor> {
  @override
  HSVColor fromEditingValue(String value) {
    print('Converting string $value to hex');
    var hex = value.replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    } else if (hex.length == 3) {
      hex = 'FF${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    }
    final parsedHex = int.tryParse('0x$hex');
    // returns null if the parsing fails
    if (parsedHex == null) {
      print('Pasing failed');
    }
    return parsedHex == null ? null : HSVColor.fromColor(Color(parsedHex));
  }

  @override
  String toEditingValue(HSVColor value) {
    var rgba = value.toColor();
    return '${rgba.red.toRadixString(16).padLeft(2, '0')}'
            '${rgba.green.toRadixString(16).padLeft(2, '0')}'
            '${rgba.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  @override
  bool get allowDrag => false;

  static final HexValueConverter instance = HexValueConverter();
}
