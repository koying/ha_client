part of '../main.dart';

class UnsupportedCardWidget extends StatelessWidget {

  final HACard card;

  const UnsupportedCardWidget({
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
        child: new Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: body
        )
    );
  }

  Widget _buildCardHeader() {
    return ListTile(
      title: Text("${card.name ?? card.type}",
          textAlign: TextAlign.left,
          overflow: TextOverflow.ellipsis,
          style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0)),
    );
  }

  List<Widget> _buildCardBody(BuildContext context) {
    List<Widget> result = [];
    result.addAll(<Widget>[
      Padding(
        padding: EdgeInsets.fromLTRB(Entity.leftWidgetPadding, 0.0, Entity.rightWidgetPadding, 0.0),
        child: Text("Card type '${card.type}' is not supported yet"),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(Entity.leftWidgetPadding, Entity.rowPadding, Entity.rightWidgetPadding, 0.0),
        child: Text("Linked entity: ${card.linkedEntity?.entityId}"),
      ),
      Padding(
        padding: EdgeInsets.fromLTRB(Entity.leftWidgetPadding, Entity.rowPadding, Entity.rightWidgetPadding, Entity.rowPadding),
        child: Text("Child entities: ${card.entities}"),
      ),
    ]);
    return result;
  }

}