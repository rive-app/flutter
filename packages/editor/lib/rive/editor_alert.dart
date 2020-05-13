import 'package:flutter/widgets.dart';
import 'package:rive_core/event.dart';

/// An alert displayed across the top of the editor's stage.
abstract class EditorAlert {
  final DetailedEvent<EditorAlert> _dismissed = DetailedEvent<EditorAlert>();
  DetailListenable<EditorAlert> get dismissed => _dismissed;
  bool get dismissOnPress => true;

  void dismiss() => _dismissed.notify(this);

  Widget build(BuildContext context);
}
