// -> editor-only
import 'package:core/core.dart';
import 'package:core/field_types/core_double_type.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/keyframe_color.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/keyframe_id.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';

/// We extend the CoreFieldTypes to support Rive specific features that we're
/// interested in per Core property, such as whether a property can be
/// keyframed. If it can be keyframed, we add logic to support creating the
/// right kind of keyframe and provide any specific details that may be
/// pertinent during keyframe creation (perhaps if it supports certain kinds of
/// interpolation).
// ignore: one_member_abstracts
abstract class KeyFrameGenerator<T extends KeyFrame> {
  T makeKeyFrame();
}

class RiveDoubleType extends CoreDoubleType
    implements KeyFrameGenerator<KeyFrameDouble> {
  @override
  KeyFrameDouble makeKeyFrame() =>
      KeyFrameDouble()..interpolation = KeyFrameInterpolation.linear;

  RiveDoubleType._constructor();
  static RiveDoubleType instance = RiveDoubleType._constructor();
}

class RiveColorType extends CoreColorType
    implements KeyFrameGenerator<KeyFrameColor> {
  RiveColorType._constructor();
  static RiveColorType instance = RiveColorType._constructor();

  @override
  KeyFrameColor makeKeyFrame() =>
      KeyFrameColor()..interpolation = KeyFrameInterpolation.linear;
}

class RiveIdType extends CoreIdType implements KeyFrameGenerator<KeyFrameId> {
  RiveIdType._constructor();
  static RiveIdType instance = RiveIdType._constructor();

  @override
  KeyFrameId makeKeyFrame() =>
      KeyFrameId()..interpolation = KeyFrameInterpolation.hold;
}

class RiveUintType extends CoreUintType {
  RiveUintType._constructor();
  static RiveUintType instance = RiveUintType._constructor();
}

class RiveStringType extends CoreStringType {
  RiveStringType._constructor();
  static RiveStringType instance = RiveStringType._constructor();
}

class RiveBoolType extends CoreBoolType {
  RiveBoolType._constructor();
  static RiveBoolType instance = RiveBoolType._constructor();
}

class RiveListIdType extends CoreListIdType {
  RiveListIdType._constructor();
  static RiveListIdType instance = RiveListIdType._constructor();
}

class RiveFractionalIndexType extends CoreFractionalIndexType {
  RiveFractionalIndexType._constructor();
  static RiveFractionalIndexType instance =
      RiveFractionalIndexType._constructor();
}
// <- editor-only
