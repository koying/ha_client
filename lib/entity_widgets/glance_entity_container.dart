part of '../main.dart';

class GlanceEntityContainer extends StatelessWidget {

  final bool showName;
  final bool showState;

  GlanceEntityContainer({
    Key key, @required this.showName, @required this.showState,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EntityWrapper entityWrapper = EntityModel.of(context).entityWrapper;
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
    result.add(
      EntityIcon(
        padding: EdgeInsets.all(0.0),
        iconSize: Sizes.iconSize,
      )
    );
    if (showState) {
      result.add(SimpleEntityState(
        textAlign: TextAlign.center,
        expanded: false,
        padding: EdgeInsets.only(top: Sizes.rowPadding),
      ));
    }
    return Center(
      child: InkResponse(
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: Sizes.iconSize*2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            //mainAxisAlignment: MainAxisAlignment.start,
            //crossAxisAlignment: CrossAxisAlignment.center,
            children: result,
          ),
        ),
        onTap: () => entityWrapper.handleTap(),
        onLongPress: () => entityWrapper.handleHold(),
      ),
    );
  }
}