import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/theme.dart';

class ViewScaleDropdown extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<double>(
      value: 1,
      items: [
        const DropdownMenuItem(
          value: 1,
          child: Text(
            '100%',
            style: TextStyle(
              color: ThemeUtils.textGreyLight,
              fontFamily: 'Roboto-Light',
              fontSize: 13,
            ),
          ),
        ),
      ],
      underline: Container(),
      onChanged: (val) {},
    );
  }
}
