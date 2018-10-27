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
    body.add(_buildCardHeader());
    body.addAll(_buildCardBody(context));
    return Card(
        child: new Column(mainAxisSize: MainAxisSize.min, children: body)
    );
  }

  Widget _buildCardHeader() {
    var result;
    if ((card.name != null) && (card.name.trim().length > 0)) {
      result = new ListTile(
        title: Text("${card.name}",
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0)),
      );
    } else {
      result = new Container(width: 0.0, height: 0.0);
    }
    return result;
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