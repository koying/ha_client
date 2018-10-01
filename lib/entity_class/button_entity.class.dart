part of '../main.dart';

class ButtonEntity extends Entity {
  ButtonEntity(Map rawData) : super(rawData);

  @override
  void sendNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(_domain, "turn_on", _entityId, null));
  }

  @override
  Widget _buildActionWidget(bool inCard, BuildContext context) {
    return FlatButton(
      onPressed: (() {
        sendNewState(null);
      }),
      child: Text(
        "EXECUTE",
        textAlign: TextAlign.right,
        style:
        new TextStyle(fontSize: Entity.STATE_FONT_SIZE, color: Colors.blue),
      ),
    );
  }
}