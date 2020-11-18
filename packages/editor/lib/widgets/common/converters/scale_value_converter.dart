import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';

/// Value converter for scale values (x and y).
class ScaleValueConverter extends InputValueConverter<double> {
  static final DoubleFormatter displayFormatter = DoubleFormatter(2);
  static final DoubleFormatter editFormatter = DoubleFormatter(4);

  static final ScaleValueConverter instance = ScaleValueConverter();

  @override
  double fromEditingValue(String value) => double.tryParse(value);

  @override
  String toDisplayValue(double value) => displayFormatter.format(value);

  @override
  String toEditingValue(double value) => editFormatter.format(value);

  @override
  double drag(double value, double amount) => value - amount;
}

/// Value converter for scale values (x and y) in percentages.
class ScalePercentageValueConverter extends InputValueConverter<double> {
  static final formatter = DoubleToPercentageFormatter();
  static final editFormatter = DoubleToPercentageFormatter(2);

  static final ScalePercentageValueConverter instance =
      ScalePercentageValueConverter();

  @override
  double fromEditingValue(String value) {
    final regex = RegExp(r'^(\-?[0-9]+([\.]?[0-9]*))%?$');
    var groups = regex.firstMatch(value);
    if (groups != null && groups.groupCount > 1) {
      var dv = double.parse(groups.group(1));
      return dv / 100;
    }
    // ignore: avoid_returning_null
    return null;
  }

  @override
  String toDisplayValue(double value) => '${formatter.format(value)}%';

  @override
  String toEditingValue(double value) => '${editFormatter.format(value)}%';

  @override
  double drag(double value, double amount) => value - (amount / 10);
}
