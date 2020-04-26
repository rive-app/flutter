import 'package:flutter/widgets.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';

/// StageItem icon usually displayed in a tree like the Hierarchy or the
/// Animation property tree. TODO: hook up real icons here (N.B. this requires
/// some level of abstraction with the StageItem as some items will return
/// simple icons and others will need to build an iconic representation of
/// themselves/their contents like the paths/shapes).
class StageItemIcon extends StatelessWidget {
  final StageItem item;

  const StageItemIcon({
    @required this.item,
    Key key,
  })  : assert(item != null, 'StageItem cannot be null'),
        super(key: key);

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF999999),
          borderRadius: BorderRadius.all(
            Radius.circular(2),
          ),
        ),
      );
}
