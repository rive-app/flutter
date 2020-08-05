import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rive_editor/widgets/common/converters/alpha_value_converter.dart';
import 'package:rive_editor/widgets/common/converters/hex_value_converter.dart';

void main() {
  test('alpha value converter', () {
    const color = Color(0xFF112233);
    final hsvColor = HSVColor.fromColor(color);
    final converter = AlphaValueConverter(hsvColor);

    expect(converter.color, const Color(0xFF112233));

    // test toEditingValue
    expect(converter.toEditingValue(hsvColor), '100%');
    expect(
        converter.toEditingValue(
          HSVColor.fromColor(const Color(0x80000000)),
        ),
        '50%');
    expect(
        converter.toEditingValue(
          HSVColor.fromColor(const Color(0x40000000)),
        ),
        '25%');

    // test fromEditingValue
    var hsvExpectedColor = HSVColor.fromColor(const Color(0xFF112233));
    var hsvCalculatedColor = converter.fromEditingValue('100');
    expect(hsvExpectedColor, hsvCalculatedColor);

    hsvExpectedColor = HSVColor.fromColor(const Color(0x00112233));
    hsvCalculatedColor = converter.fromEditingValue('0');
    expect(hsvExpectedColor, hsvCalculatedColor);

    hsvExpectedColor = HSVColor.fromColor(const Color(0x80112233));
    hsvCalculatedColor = converter.fromEditingValue('50');
    // Account for rounding errors
    expect(
      hsvExpectedColor.alpha.toStringAsFixed(2),
      hsvCalculatedColor.alpha.toStringAsFixed(2),
    );

    expect(converter.fromEditingValue('malformed'), null);
  });

  test('hex value converter', () {
    // test fromEditingValue
    final converter = HexValueConverter();
    expect(
      converter.fromEditingValue('AABBCC'),
      HSVColor.fromColor(const Color(0xFFAABBCC)),
    );
    expect(
      converter.fromEditingValue('ABC'),
      HSVColor.fromColor(const Color(0xFFAABBCC)),
    );
    expect(
      converter.fromEditingValue('80112233'),
      HSVColor.fromColor(const Color(0x80112233)),
    );
    expect(converter.fromEditingValue('malformed'), null);
  });
}
