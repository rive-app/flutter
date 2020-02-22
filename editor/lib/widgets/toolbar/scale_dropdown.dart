import 'package:flutter/material.dart';

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
            style: TextStyle(color: Color(0xFF666666)),
          ),
        ),
      ],
      underline: Container(),
      onChanged: (val) {},
    );
  }
}
