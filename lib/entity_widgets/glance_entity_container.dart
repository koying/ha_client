part of '../main.dart';

class GlanceEntityContainer extends StatelessWidget {
  GlanceEntityContainer({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        EntityName(
          padding: EdgeInsets.all(0.0),
        ),
        EntityIcon(
          padding: EdgeInsets.all(0.0),
          iconSize: Sizes.largeIconSize,
        ),
        SimpleEntityState(
          textAlign: TextAlign.center,
          expanded: false,
          padding: EdgeInsets.all(0.0),
        )
      ],
    );
  }
}