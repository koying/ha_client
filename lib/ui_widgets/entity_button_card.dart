part of '../main.dart';

class EntityButtonCardWidget extends StatelessWidget {

  final HACard card;

  const EntityButtonCardWidget({
    Key key,
    this.card
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (card.linkedEntity!= null && card.linkedEntity.entity.isHidden) {
      return Container(width: 0.0, height: 0.0,);
    }
    card.linkedEntity.displayName = card.name;
    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, Sizes.rowPadding, Sizes.rightWidgetPadding, Sizes.rowPadding),
        child: EntityModel(
          entityWrapper: card.linkedEntity,
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