import 'package:flutter/material.dart';
import 'package:core/core.dart';
import 'package:rive_editor/widgets/common/converters/input_value_converter.dart';
import 'package:rive_editor/widgets/common/core_text_field.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class PropertyDual<T> extends StatelessWidget {
  final List<Core> objects;
  final int propertyKeyA;
  final int propertyKeyB;
  final String iconName;
  final String labelA;
  final String labelB;
  final String name;
  final bool linkable;
  final InputValueConverter<T> converter;

  const PropertyDual({
    @required this.objects,
    @required this.propertyKeyA,
    @required this.propertyKeyB,
    this.name,
    this.iconName,
    this.linkable = false,
    this.labelA = '',
    this.labelB = '',
    this.converter,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 5, bottom: 5),
      padding: const EdgeInsets.only(left: 20, right: 20),
      height: 35,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Container(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                    flex: 1,
                    child: Container(
                      child: Text(
                        name,
                        style: RiveTheme.of(context)
                            .textStyles
                            .inspectorPropertyLabel,
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: linkable
                        ? TintedIcon(
                            icon: 'link',
                            color: RiveTheme.of(context)
                                .textStyles
                                .inspectorPropertySubLabel
                                .color,
                          )
                        : Container(),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  flex: 1,
                  child: CoreTextField(
                    objects: objects,
                    propertyKey: propertyKeyA,
                    converter: converter,
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Text(
                    labelA,
                    style: RiveTheme.of(context)
                        .textStyles
                        .inspectorPropertySubLabel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Flexible(
                  flex: 1,
                  child: CoreTextField<T>(
                    objects: objects,
                    propertyKey: propertyKeyB,
                    converter: converter,
                  ),
                ),
                Flexible(
                  flex: 1,
                  child: Text(
                    labelB,
                    style: RiveTheme.of(context)
                        .textStyles
                        .inspectorPropertySubLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
