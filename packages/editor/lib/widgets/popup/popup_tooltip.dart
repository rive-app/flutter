import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/path_widget.dart';
import 'package:rive_editor/widgets/popup/base_popup.dart';
import 'package:rive_editor/widgets/popup/list_popup.dart';
import 'package:rive_editor/widgets/popup/tooltip_item.dart';

final _pathArrow = Path()
  ..lineTo(6, -6)
  ..lineTo(12, 0)
  ..close();

class TooltipPopup {
  Popup _popup;
  List<TooltipItem> items;

  TooltipPopup(this.items);

  factory TooltipPopup.show(
    BuildContext context, {
    @required List<TooltipItem> items,
    @required ListPopupItemBuilder<TooltipItem> itemBuilder,
    double width = 177,
    double margin = 10,
    Offset offset = const Offset(0, 10),
    bool showArrow = true,
    Alignment alignment = Alignment.bottomCenter,
    Color background = const Color.fromRGBO(17, 17, 17, 1),
  }) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final boxOffset = renderBox.localToGlobal(Offset.zero);

    final media = MediaQuery.of(context);
    final halfWidth = width / 2;

    final position = boxOffset + alignment.alongSize(size);
    final top = position.dy + offset.dy;
    final left = position.dx + offset.dx - halfWidth;

    TooltipPopup tooltip;

    tooltip = TooltipPopup(items);

    tooltip._popup = Popup.show(context, builder: (popupContext) {
      return Positioned(
          left: left,
          top: top,
          width: width,
          child: Material(
              type: MaterialType.transparency,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (showArrow) ...[
                    PathWidget(
                      path: _pathArrow,
                      nudge: Offset(halfWidth - 6, 0),
                      paint: Paint()
                        ..color = background
                        ..style = PaintingStyle.fill
                        ..isAntiAlias = true,
                    )
                  ],
                  LayoutBuilder(builder: (popupContext, constraints) {
                    if (items.isEmpty) {
                      return Container();
                    }
                    final height = min(
                        media.size.height - top,
                        items.fold<double>(
                                0.0,
                                (accumulator, element) =>
                                    accumulator + element.height) +
                            margin * 2);

                    return Container(
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3473),
                              offset: const Offset(0, 30),
                              blurRadius: 30,
                            )
                          ],
                        ),
                        height: height,
                        child: Scrollbar(
                            child: ListView.builder(
                                physics: const ClampingScrollPhysics(),
                                padding: EdgeInsets.symmetric(vertical: margin),
                                itemCount: items.length,
                                itemBuilder: (listContext, index) {
                                  final item = items[index];
                                  return Container(
                                      height: item.height,
                                      child: itemBuilder(
                                          listContext, item, false));
                                })));
                  }),
                ],
              )));
    });

    return tooltip;
  }

  bool get isOpen => Popup.isOpen(_popup);

  bool close() {
    return Popup.remove(_popup);
  }
}
