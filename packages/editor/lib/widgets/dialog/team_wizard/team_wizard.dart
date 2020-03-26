import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:rive_editor/widgets/dialog/team_wizard/panel_two.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/subscription_package.dart';
import 'package:rive_editor/widgets/dialog/rive_dialog.dart';
import 'package:rive_editor/widgets/dialog/team_wizard/panel_one.dart';

Future<T> showTeamWizard<T>({BuildContext context}) {
  return showRiveDialog(
    context: context,
    builder: (context) => const Wizard(),
  );
}

/// The main panel for holding the team wizard views
class Wizard extends StatefulWidget {
  const Wizard({Key key}) : super(key: key);
  @override
  _WizardState createState() => _WizardState();
}

class _WizardState extends State<Wizard> {
  TeamSubscriptionPackage _sub;
  WizardPanel activePanel = WizardPanel.one;

  @override
  void initState() {
    _sub = TeamSubscriptionPackage()
      // Listen for changes to the package and handle appropriately
      ..addListener(
        () => setState(() => activePanel =
            _sub.isStep1Valid ? WizardPanel.two : WizardPanel.one),
      );
    super.initState();
  }

  @override
  void dispose() {
    _sub.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return activePanel == WizardPanel.one
        ? TeamWizardPanelOne(_sub)
        : TeamWizardPanelTwo(_sub);
  }
}
