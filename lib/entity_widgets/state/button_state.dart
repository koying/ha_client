part of '../../main.dart';

class ButtonStateWidget extends StatelessWidget {

  void _setNewState(Entity entity) {
    eventBus.fire(new ServiceCallEvent(entity.domain, "turn_on", entity.entityId, null));
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return SizedBox(
      height: 34.0,
      child: FlatButton(
        onPressed: (() {
          _setNewState(entityModel.entity);
        }),
        child: Text(
          "EXECUTE",
          textAlign: TextAlign.right,
          style:
          new TextStyle(fontSize: Entity.stateFontSize, color: Colors.blue),
        ),
      )
    );
  }
}