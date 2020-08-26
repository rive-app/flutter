import 'package:flutter/widgets.dart';
import 'package:rive_core/bones/tendon.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/widgets/common/converters/percentage_input_converter.dart';
import 'package:rive_editor/widgets/inspector/properties/inspector_text_field.dart';
import 'package:rive_editor/widgets/inspector/properties/property_item.dart';
import 'package:rive_editor/widgets/properties_builder.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class PropertyTendon extends StatelessWidget {
  final Iterable<Tendon> tendons;
  final Iterable<StageVertex> vertices;
  final Color color;
  final int boneIndex;
  final int boundBoneCount;
  const PropertyTendon({
    Key key,
    this.tendons,
    this.color,
    this.vertices,
    this.boneIndex,
    this.boundBoneCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Note that left padding is 15 as the popout button has a padding of 5,
      // bringing the total left padding to 20. This is so the icon aligns at 20
      // but the hit area of the button starts at 15.
      padding: const EdgeInsets.only(top: 8, bottom: 0, left: 20, right: 15),
      child: PropertyItem(
        prefix: (context) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: TintedIcon(
            icon: PackedIcon.bone,
            color: color,
          ),
        ),
        components: tendons,
        postfix: vertices == null || vertices.isEmpty
            ? null
            : (context) => SizedBox(
                  width: 40,
                  child: PropertiesBuilder<double, StageVertex>(
                    objects: vertices,
                    filter: (vertex) => vertex.component.isActive,
                    builder: (context, weight, _) {
                      return InspectorTextField(
                        converter: ClampedPercentageInputConverter.instance,
                        value: weight,
                        change: (double value) {
                          for (final vertex in vertices) {
                            vertex.setWeight(
                              boneIndex,
                              boundBoneCount,
                              value,
                            );
                          }
                        },
                      );
                    },
                    getValue: (object) => object.getWeight(boneIndex),
                    listen: (object, enable, callback) {
                      object.listenToWeightChange(enable, callback);
                    },
                    frozen: false,
                  ),
                ),
      ),
    );
  }
}
