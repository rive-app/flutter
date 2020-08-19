import 'package:flutter/widgets.dart';
import 'package:rive_core/bones/tendon.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/inspector/properties/property_item.dart';
import 'package:rive_editor/widgets/tinted_icon.dart';

class PropertyTendon extends StatelessWidget {
  final Iterable<Tendon> tendons;
  final Color color;
  const PropertyTendon({
    Key key,
    this.tendons,
    this.color,
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
      ),
    );
  }
}
