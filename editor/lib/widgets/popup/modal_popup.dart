import 'package:flutter/material.dart';

// import 'base_popup.dart';

class ModalPopup {
  final WidgetBuilder builder;
  final Size size;
  final double elevation;

  const ModalPopup({
    this.builder,
    this.size,
    this.elevation = 8.0,
  });

  Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) => Center(
        child: SizedBox.fromSize(
          size: size,
          child: Material(
            color: const Color.fromRGBO(50, 50, 50, 1.0),
            elevation: elevation,
            borderRadius: BorderRadius.circular(10),
            child: builder(context),
          ),
        ),
      ),
    );
  }
}
