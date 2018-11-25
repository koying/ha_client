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
    card.linkedEntityWrapper.displayName = card.name?.toUpperCase() ?? card.linkedEntityWrapper.displayName.toUpperCase();
    return Card(
      child: EntityModel(
        entityWrapper: card.linkedEntityWrapper,
        child: ButtonEntityContainer(),
        handleTap: true
      )
    );
  }

}