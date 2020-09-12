import 'package:flutter/material.dart';
import 'package:rive_core/bones/skeletal_component.dart';
import 'package:rive_core/bones/skin.dart';
import 'package:rive_editor/rive/stage/items/stage_bone.dart';
import 'package:rive_editor/rive/stage/items/stage_vertex.dart';
import 'package:rive_editor/rive/stage/stage_item.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';
import 'package:rive_editor/widgets/inspector/inspection_set.dart';
import 'package:rive_editor/widgets/inspector/inspector_builder.dart';
import 'package:rive_editor/widgets/inspector/inspector_group.dart';
import 'package:rive_editor/widgets/inspector/properties/property_tendon.dart';
import 'package:rive_editor/widgets/inspector/select_stage_item_helper.dart';
import 'package:rive_core/bones/skinnable.dart';

/// Example inspector builder with combo boxes.
class InspectSkin extends ListenableInspectorBuilder {
  final SelectStageItemHelper selectionHelper = SelectStageItemHelper();
  bool _isExpanded = true;
  Skinnable _skinnable;

  @override
  void clean() {
    selectionHelper.dismiss();
    for (final stageBone in _coloredBones) {
      stageBone.highlightColor = null;
    }
    _coloredBones.clear();
  }

  final List<StageBone> _coloredBones = [];

  @override
  List<WidgetBuilder> expand(
      BuildContext panelContext, InspectionSet inspecting) {
    var vertexEditor = inspecting.fileContext.vertexEditor;
    var showWeights =
        vertexEditor.isActive && vertexEditor.editingPaths.isNotEmpty;
    var skin = _skinnable.skin;
    var boneColors = RiveTheme.of(panelContext).colors.boundBones;
    if (skin != null) {
      for (int i = 0, l = skin.tendons.length; i < l; i++) {
        var stageBone = skin.tendons[i].bone.stageItem as StageBone;
        _coloredBones.add(stageBone);
        stageBone.highlightColor = boneColors[i % l];
      }
    }

    return [
      (context) => InspectorGroup(
            name: 'Bind Bones',
            isExpanded: _isExpanded,
            tapExpand: () {
              _isExpanded = !_isExpanded;
              notifyListeners();
            },
            add: () async {
              var items = await selectionHelper.show(
                  inspecting.fileContext,
                  'Pick a bone to bind.',
                  (item) => item.component is SkeletalComponent);
              for (final item in items) {
                Skin.bind(item.component as SkeletalComponent, _skinnable);
              }
              inspecting.fileContext.core.captureJournalEntry();
            },
          ),
      if (_isExpanded && skin != null)
        for (int i = 0, l = skin.tendons.length; i < l; i++)
          (context) => PropertyTendon(
                tendons: [
                  skin.tendons[i],
                ],
                color: boneColors[i % l],
                boneIndex: i,
                vertices: showWeights
                    ? inspecting.stageItems.whereType<StageVertex>()
                    : null,
                boundBoneCount: l,
              ),
    ];
  }

  @override
  bool validate(InspectionSet inspecting) {
    var vertexEditor = inspecting.fileContext.vertexEditor;
    if (vertexEditor.isActive && vertexEditor.editingPaths.length == 1) {
      _skinnable = vertexEditor.editingPaths.first;
      changeWhen([_skinnable.skinChanged]);
      return true;
    }
    if (inspecting.components.length != 1) {
      return false;
    }
    var selectedComponent = inspecting.components.first;
    if (selectedComponent is Skinnable) {
      _skinnable = selectedComponent as Skinnable;
      changeWhen([_skinnable.skinChanged]);
      return true;
    }
    return false;
  }
}
