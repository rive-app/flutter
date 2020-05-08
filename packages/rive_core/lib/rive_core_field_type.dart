import 'package:core/core.dart';
import 'package:core/field_types/core_double_type.dart';
import 'package:rive_core/animation/keyframe.dart';
import 'package:rive_core/animation/keyframe_double.dart';
import 'package:rive_core/animation/keyframe_interpolation.dart';

/// We extend the CoreFieldTypes to support Rive specific features that we're
/// interested in per Core property, such as whether a property can be
/// keyframed. If it can be keyframed, we add logic to support creating the
/// right kind of keyframe and provide any specific details that may be
/// pertinent during keyframe creation (perhaps if it supports certain kinds of
/// interpolation).
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

class RiveIdType extends CoreIdType {
  RiveIdType._constructor();
  static RiveIdType instance = RiveIdType._constructor();
}

class RiveIntType extends CoreIntType {
  RiveIntType._constructor();
  static RiveIntType instance = RiveIntType._constructor();
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
