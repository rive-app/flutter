import 'package:flutter/material.dart';

Widget _riveDialogTransition(BuildContext context, Animation<double> animation,
    Animation<double> secondaryAnimation, Widget child) {
  return FadeTransition(
    opacity: CurvedAnimation(
      parent: animation,
      curve: Curves.easeOut,
    ),
    child: child,
  );
}

/// Show a Rive styled dialog. It was necessary to use a general dialog here in
/// order to override the barrier's color.
Future<T> showRiveDialog<T>({
  @required BuildContext context,
  WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final ThemeData theme = Theme.of(context, shadowThemeOnly: true);
  return showGeneralDialog<T>(
    context: context,
    pageBuilder: (BuildContext buildContext, Animation<double> animation,
        Animation<double> secondaryAnimation) {
      final Widget pageChild = Container(
        margin: const EdgeInsets.all(20),
        // TODO: material is too heavy to use here, replace with something
        // lighterweight that keeps text styled properly.
        // Look at wrapping in Theme/TextTheme
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Container(
                  margin: EdgeInsets.only(top: 60),
                  constraints: const BoxConstraints(
                    // TODO: what should be the scale behavior? Talk to Guido
                    minWidth: 300,
                    maxWidth: 800,
                    minHeight: 300,
                    maxHeight: double.infinity,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Builder(builder: builder),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 100,
                        spreadRadius: 0,
                        offset: const Offset(0, 50),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      return SafeArea(
        child: Builder(
          builder: (BuildContext context) {
            return theme != null
                ? Theme(data: theme, child: pageChild)
                : pageChild;
          },
        ),
      );
    },
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black.withOpacity(0.6),
    transitionDuration: const Duration(milliseconds: 150),
    transitionBuilder: _riveDialogTransition,
    useRootNavigator: true,
  );
}
