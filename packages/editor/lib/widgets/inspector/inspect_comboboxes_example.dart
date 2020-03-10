import 'package:flutter/material.dart';
import 'package:rive_editor/widgets/common/combo_box.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';

/// Example inspector builder with combo boxes.
class InspectComboBoxExample extends InspectorBuilder {
  @override
  List<WidgetBuilder> expand(InspectionSet inspecting) => [
        (context) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: KILLME_ComboExamples(),
            ),
      ];

  @override
  bool validate(InspectionSet inspecting) => true;
}

/// luigi: All of the code below here is just for example purposes to show how
/// to interface with the new combo-boxes. Feel free to pour napalm all over
/// this at any point. Maybe I should move it to Notion or a ReadMe or
/// something.
enum _FakeBlendModes {
  none,
  srcIn,
  srcOut,
  additive,
  multiply,
  blah,
  blahBlahBlah
}

class KILLME_ComboExamples extends StatefulWidget {
  static const busters = [
    'Spengler',
    'Zeddemore',
    'Stantz',
    'Venkman',
  ];

  @override
  _KILLME_ComboExamplesState createState() => _KILLME_ComboExamplesState();
}

class _KILLME_ComboExamplesState extends State<KILLME_ComboExamples> {
  String _buster1;
  String _buster2;
  _FakeBlendModes _blendMode;

  @override
  void initState() {
    super.initState();
    _blendMode = _FakeBlendModes.none;
    _buster1 = KILLME_ComboExamples.busters.first;
    _buster2 = KILLME_ComboExamples.busters.last;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Padding around text label to align baseline of combo box. This
            // might need to be handled differently in production to assure rows
            // are of the same heights.
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Hero',
                style: RiveTheme.of(context)
                    .textStyles
                    .basic
                    .copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(
              width: 40,
            ),
            ComboBox(
              sizing: ComboSizing.expanded,
              typeahead: true,
              options: KILLME_ComboExamples.busters,
              value: _buster1,
              chooseOption: (String buster) {
                setState(() {
                  _buster1 = buster;
                });
              },
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Padding around text label to align baseline of combo box. This
            // might need to be handled differently in production to assure rows
            // are of the same heights.
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Hero',
                style: RiveTheme.of(context)
                    .textStyles
                    .basic
                    .copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(
              width: 40,
            ),
            ComboBox(
              sizing: ComboSizing.expanded,
              options: KILLME_ComboExamples.busters,
              value: _buster2,
              chooseOption: (String buster) {
                setState(() {
                  _buster2 = buster;
                });
              },
            ),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Padding around text label to align baseline of combo box. This
            // might need to be handled differently in production to assure rows
            // are of the same heights.
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Blend Mode',
                style: RiveTheme.of(context)
                    .textStyles
                    .basic
                    .copyWith(color: Colors.white),
              ),
            ),
            const SizedBox(
              width: 40,
            ),
            ComboBox(
              sizing: ComboSizing.expanded,
              options: _FakeBlendModes.values,
              chooseOption: (_FakeBlendModes blendMode) {
                setState(() {
                  _blendMode = blendMode;
                });
              },
              toLabel: (_FakeBlendModes blendMode) {
                switch (blendMode) {
                  case _FakeBlendModes.none:
                    return "None";
                  case _FakeBlendModes.additive:
                    return "Additive";
                  case _FakeBlendModes.blah:
                    return "Blah";
                  case _FakeBlendModes.blahBlahBlah:
                    return "Blah blah blah";
                  case _FakeBlendModes.multiply:
                    return "Multiply";
                  case _FakeBlendModes.srcIn:
                    return "Source In";
                  case _FakeBlendModes.srcOut:
                    return "Source Out";
                }
                return "???";
              },
              value: _blendMode,
            )
          ],
        ),
      ],
    );
  }
}
