import 'package:flutter/widgets.dart';
import 'package:rive_editor/packed_icon.dart';
import 'package:rive_editor/widgets/inherited_widgets.dart';

/// Panel showing getting started assets
class GetStartedPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);

    return Container(
      color: theme.colors.panelBackgroundLightGrey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: const <Widget>[
            Expanded(
              child: Center(
                child: MiddlePanel(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiddlePanel extends StatelessWidget {
  const MiddlePanel();
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 30),
        LargeCard(
          backgroundImageAsset: 'assets/images/space_man.png',
          icon: PackedIcon.play,
        ),
        const SizedBox(height: 30),
        LargeCard(
          backgroundImageAsset: 'assets/images/mother_of_dashes.png',
          icon: PackedIcon.play,
        ),
      ],
    );
  }
}

class LargeCard extends StatelessWidget {
  const LargeCard(
      {@required this.backgroundImageAsset, @required this.icon, Key key})
      : super(key: key);
  final String backgroundImageAsset;
  final Iterable<PackedIcon> icon;

  @override
  Widget build(BuildContext context) {
    final theme = RiveTheme.of(context);

    return Container(
      width: 685,
      height: 384,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(backgroundImageAsset),
          fit: BoxFit.cover,
        ),
        borderRadius: const BorderRadius.all(
          Radius.circular(10),
        ),
      ),
      child: Positioned(
        bottom: 20,
        left: 20,
        child: Text('Hello'),
        /*
        child: SizedBox(
          height: 20,
          width: 20,
          child: TintedIcon(
            icon: icon,
            color: const Color(0xFFFFFFFF),
          ),
          */
      ),
    );
  }
}

/// Size of large card: 685x384
