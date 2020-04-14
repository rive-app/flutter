import 'package:flutter/rendering.dart';

abstract class LateDrawStageTool {
    void lateDraw(PaintingContext context, Offset offset, Size viewSize);
}