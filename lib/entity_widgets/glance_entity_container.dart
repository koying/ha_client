part of '../main.dart';

class GlanceEntityContainer extends StatelessWidget {

  final bool showName;
  final bool showState;
  final bool nameInTheBottom;
  final double iconSize;
  final double nameFontSize;
  final bool expanded;

  GlanceEntityContainer({
    Key key,
    @required this.showName,
    @required this.showState,
    this.nameInTheBottom: false,
    this.iconSize: Sizes.iconSize,
    this.nameFontSize: Sizes.smallFontSize,
    this.expanded: false
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EntityWrapper entityWrapper = EntityModel.of(context).entityWrapper;
    List<Widget> result = [];
    if (!nameInTheBottom) {
      if (showName) {
        result.add(EntityName(
          padding: EdgeInsets.only(bottom: Sizes.rowPadding),
          textOverflow: TextOverflow.ellipsis,
          wordsWrap: false,
          textAlign: TextAlign.center,
          fontSize: nameFontSize,
        ));
      }
    } else {
      if (showState) {
        result.add(SimpleEntityState(
          textAlign: TextAlign.center,
          expanded: false,
          padding: EdgeInsets.only(top: Sizes.rowPadding),
        ));
      }
    }
    result.add(
      EntityIcon(
        padding: EdgeInsets.all(0.0),
        iconSize: iconSize,
      )
    );
    if (!nameInTheBottom) {
      if (showState) {
        result.add(SimpleEntityState(
          textAlign: TextAlign.center,
          expanded: false,
          padding: EdgeInsets.only(top: Sizes.rowPadding),
        ));
      }
    } else {
      result.add(EntityName(
        padding: EdgeInsets.only(bottom: Sizes.rowPadding),
        textOverflow: TextOverflow.ellipsis,
        wordsWrap: false,
        textAlign: TextAlign.center,
        fontSize: nameFontSize,
      ));
    }
    
    if (expanded) {
      return InkWell(
        onTap: () => entityWrapper.handleTap(),
        onLongPress: () => entityWrapper.handleHold(),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 100.0),
          child: FittedBox(
            fit: BoxFit.fitHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              //mainAxisAlignment: MainAxisAlignment.start,
              //crossAxisAlignment: CrossAxisAlignment.center,
              children: result,
            ),
          ),
        ),
      );
    } else {
      return Center(
        child: InkResponse(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: Sizes.iconSize * 2),
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
}