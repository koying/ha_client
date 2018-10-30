part of '../main.dart';

class EntitiesCardWidget extends StatelessWidget {

  final HACard card;

  const EntitiesCardWidget({
    Key key,
    this.card
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((card.linkedEntity!= null) && (card.linkedEntity.isHidden)) {
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
    card.entities.forEach((Entity entity) {
      if (!entity.isHidden) {
        result.add(
            Padding(
              padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
              child: entity.buildDefaultWidget(context),
            ));
      }
    });
    return result;
  }

}