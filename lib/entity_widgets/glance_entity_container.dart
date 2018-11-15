part of '../main.dart';

class GlanceEntityContainer extends StatelessWidget {

  final bool showName;
  final bool showState;

  GlanceEntityContainer({
    Key key, @required this.showName, @required this.showState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> result = [];
    if (showName) {
      result.add(EntityName(
        padding: EdgeInsets.only(bottom: Sizes.rowPadding),
        textOverflow: TextOverflow.ellipsis,
        wordsWrap: false,
        textAlign: TextAlign.center,
        fontSize: Sizes.smallFontSize,
      ));
    }
    result.add(EntityIcon(
      padding: EdgeInsets.all(0.0),
      iconSize: Sizes.largeIconSize,
    ));
    if (showState) {
      result.add(SimpleEntityState(
        textAlign: TextAlign.center,
        expanded: false,
        padding: EdgeInsets.only(top: Sizes.rowPadding),
      ));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: result,
    );
  }
}