import 'package:flutter/material.dart';

import 'settings_panel.dart';

enum SettingsPanelContents { settings, members, plan }

/// This is a settings modal panel that implements the SettingsPanel widget. Not
/// sure about this pattern, Flutter usually shies away from subclassing like
/// this but it seems to make sense for enumerated panels like this. This seems
/// like a nice way to build out a lot of these, however. Open to
/// suggestions/replacements!
class TeamSettingsPanel extends SettingsPanel<SettingsPanelContents> {
  const TeamSettingsPanel({Key key})
      : super(
          key: key,
          contents: SettingsPanelContents.values,
        );

  @override
  String label(SettingsPanelContents type) {
    switch (type) {
      case SettingsPanelContents.settings:
        return "Team Settings";
      case SettingsPanelContents.members:
        return "Members";
      case SettingsPanelContents.plan:
        return "Plan";
    }
    return "??";
  }

  @override
  Widget buildSettingsPage(BuildContext context, SettingsPanelContents type) {
    // Should probably create a SettingsSection widget that has vertical
    // scrolling and an optional Save Changes button on the bottom right that we
    // can re-use for all these pages. See Figma:
    // https://www.figma.com/file/nlGengoVlxjmxLwAfWOUoU/Rive-App?node-id=1678%3A21710
    switch(type) {
      case SettingsPanelContents.settings:
        return const Text("build team settings");
      case SettingsPanelContents.members:
        return const Text("build member settings");
      case SettingsPanelContents.plan:
        return const Text("build plan settings");
    }
    
    return const Text("???");
  }
}
