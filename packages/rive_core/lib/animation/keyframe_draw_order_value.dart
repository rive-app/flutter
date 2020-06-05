import 'package:core/core.dart';
import 'package:fractional/fractional.dart';
import 'package:core/id.dart';
import 'package:logging/logging.dart';
import 'package:rive_core/animation/keyframe_draw_order.dart';
import 'package:rive_core/component.dart';
import 'package:rive_core/drawable.dart';
import 'package:rive_core/src/generated/animation/keyframe_draw_order_value_base.dart';

// -> editor-only
final _log = Logger('KeyFrameDrawOrderValue');
// <- editor-only

class KeyFrameDrawOrderValue extends KeyFrameDrawOrderValueBase {
  @override
  void onAdded() {
    // -> editor-only
    if (keyframeId != null) {
      KeyFrameDrawOrder drawOrderKF = context?.resolve(keyframeId);
      if (drawOrderKF == null) {
        _log.finest('Failed to resolve keyframe for DrawOrderValue '
            'with id $keyframeId');
      } else {
        drawOrderKF.internalAddValue(this);
      }
    }
    Component component;
    if (drawableId == null ||
        (component = context?.resolve<Component>(drawableId)) == null) {
      _log.finest('Removing KeyFrameDrawOrderValue as we couldn\'t '
          'resolve an object with id $drawableId.');
      _remove();
    } else {
      component.whenDeleted(_remove);
    }
    // <- editor-only
  }

  void _remove() {
    context.removeObject(this);
  }

  KeyFrameDrawOrder get keyFrameDrawOrder => context?.resolve(keyframeId);

  @override
  void drawableIdChanged(Id from, Id to) {
    // Should never change once created.
  }

  @override
  void keyframeIdChanged(Id from, Id to) {
    // Should never change once created.
  }

  @override
  void onAddedDirty() {
    // TODO: implement onAddedDirty
  }

  @override
  void onRemoved() {
    // -> editor-only
    keyFrameDrawOrder?.internalRemoveValue(this);
    // <- editor-only
  }

  @override
  void valueChanged(FractionalIndex from, FractionalIndex to) {
    keyFrameDrawOrder?.internalValueChanged();
  }

  void apply(CoreContext context) {
    var drawable = context.resolve<Drawable>(drawableId);
    if (drawable != null) {
      drawable.drawOrder = value;
    }
  }
}
