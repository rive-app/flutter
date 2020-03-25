import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/separator.dart';
import 'package:rive_editor/widgets/common/underline.dart';
import 'package:rive_editor/widgets/theme.dart';

import 'settings_panel.dart';

class TeamSettings extends SettingsScreen {
  TeamSettings() : super('Team Settings');

  @override
  Widget screenBuilder(BuildContext context) {
    final theme = RiveThemeData();
    final colors = theme.colors;
    final textStyles = theme.textStyles;
    return SingleChildScrollView(
        child: Padding(
      padding: const EdgeInsets.only(top: 30, left: 30, right: 30),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Account',
                  style: textStyles.fileGreyTextLarge,
                ),
                const Spacer(),
                SettingsTextField(),
                const SizedBox(width: 30),
                SettingsTextField(),
              ],
            ),
            Separator(color: colors.fileLineGrey),
            Row(
              children: <Widget>[
                Text(
                  'For Hire',
                  style: textStyles.fileGreyTextLarge,
                ),
                Column(children: [
                  Row(
                    children: [SettingsTextField()],
                  )
                ])
              ],
            ),
            Separator(color: colors.fileLineGrey),
            Row(
              children: <Widget>[
                Text(
                  'Social',
                  style: textStyles.fileGreyTextLarge,
                ),
              ],
            )
          ]),
    ));
  }
}

class SettingsTextField extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsTextFieldState();
}

class _SettingsTextFieldState extends State<SettingsTextField> {
  bool _hasFocus = false;
  final _focusNode = FocusNode(canRequestFocus: true, skipTraversal: true);
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_focusChange);
  }

  void _focusChange() {
    setState(() {
      _hasFocus = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus) {
      _controller.selection =
          TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = RiveColors();
    final textStyles = TextStyles();

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 180,
        minWidth: 75,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text('Label'),
          Underline(
              // color: _hasFocus ? colors.commonDarkGrey : colors.inputUnderline,
              color: Colors.transparent,
              child: TextField(
                  textAlign: TextAlign.left,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colors.inputUnderline)
                        ),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: colors.commonDarkGrey)
                        ),
                  ),
                  style: textStyles.fileGreyTextLarge)),
        ],
      ),
    );
  }
}
