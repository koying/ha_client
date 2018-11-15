part of '../main.dart';

class EntitiesCardWidget extends StatelessWidget {

  final HACard card;

  const EntitiesCardWidget({
    Key key,
    this.card
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((card.linkedEntity!= null) && (card.linkedEntity.entity.isHidden)) {
      return Container(width: 0.0, height: 0.0,);
    }
    List<Widget> body = [];
    body.add(CardHeaderWidget(name: card.name));
    body.addAll(_buildCardBody(context));
    return Card(
        child: new Column(mainAxisSize: MainAxisSize.min, children: body)
    );
  }

  List<Widget> _buildCardBody(BuildContext context) {
    List<Widget> result = [];
    card.entities.forEach((EntityWrapper entity) {
      if (!entity.entity.isHidden) {
        result.add(
            Padding(
              padding: EdgeInsets.fromLTRB(0.0, Sizes.rowPadding, 0.0, Sizes.rowPadding),
              child: EntityModel(
                  entity: entity,
                  handleTap: true,
                  child: entity.entity.buildDefaultWidget(context)
              ),
            ));
      }
    });
    return result;
  }

}