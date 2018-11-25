part of '../main.dart';

class EntityButtonCardWidget extends StatelessWidget {

  final HACard card;

  const EntityButtonCardWidget({
    Key key,
    this.card
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (card.linkedEntityWrapper!= null && card.linkedEntityWrapper.entity.isHidden) {
      return Container(width: 0.0, height: 0.0,);
    }
    if (card.name != null) {
      card.linkedEntityWrapper.displayName = card.name;
    }
    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, Sizes.rowPadding, Sizes.rightWidgetPadding, Sizes.rowPadding),
        child: EntityModel(
          entityWrapper: card.linkedEntityWrapper,
          child: GlanceEntityContainer(
            showName: true,
            showState: false,
            nameInTheBottom: true,
            iconSize: Sizes.largeIconSize,
            nameFontSize: Sizes.nameFontSize,
            expanded: true,
          ),
          handleTap: true
        ),
      )
    );
  }

}