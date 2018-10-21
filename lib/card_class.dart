part of 'main.dart';

class CardWidget extends StatelessWidget {

  final List<Entity> entities;
  final String friendlyName;

  const CardWidget({
    Key key,
    this.entities,
    this.friendlyName
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    if (entityModel != null) {
      final groupEntity = entityModel.entity;
      if ((groupEntity!= null) && (groupEntity.isHidden)) {
        return Container(width: 0.0, height: 0.0,);
      }
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
    if ((friendlyName != null) && (friendlyName.trim().length > 0)) {
      result = new ListTile(
        //leading: const Icon(Icons.device_hub),
        //subtitle: Text(".."),
        //trailing: Text("${data["state"]}"),
        title: Text("$friendlyName",
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
    entities.forEach((Entity entity) {
      result.add(
        Padding(
          padding: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
          child: entity.buildDefaultWidget(context),
        ));
    });
    return result;
  }

}