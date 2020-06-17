import 'package:flutter/widgets.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

class SettingsPanelSection extends StatelessWidget {
  const SettingsPanelSection({
    @required this.label,
    this.labelExtra,
    this.subLabel,
    this.secondaryColor,
    this.contents,
    Key key,
  }) : super(key: key);

  final String label;
  final WidgetBuilder contents;

  /// Define an extra bit of text that'll be displayed inline with the label.
  /// Uses [secondaryColor].
  final String labelExtra;

  /// Define a secondary label that'll appear beneath the first label.
  /// Also uses [secondaryColor].
  final String subLabel;

  /// If defined, it'll be applied to [labelExtra] and [subLabel],
  /// otherwise it'll default to [greyText]'s color.
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    final textStyles = RiveTheme.of(context).textStyles;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 170,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                        text: label,
                        style: textStyles.greyText.copyWith(fontSize: 16)),
                    if (labelExtra != null)
                      TextSpan(
                        text: labelExtra,
                        style: textStyles.greyText
                            .copyWith(color: secondaryColor, fontSize: 16),
                      ),
                  ],
                ),
              ),
              if (subLabel != null) ...[
                const SizedBox(height: 11),
                Text(
                  subLabel,
                  style: textStyles.greyText.copyWith(color: secondaryColor),
                ),
              ]
            ],
          ),
        ),
        const Spacer(),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 75,
            maxWidth: 405,
          ),
          child: contents(context),
        )
      ],
    );
  }
}
