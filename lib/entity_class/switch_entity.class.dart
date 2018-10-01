part of '../main.dart';

class SwitchEntity extends Entity {
  SwitchEntity(Map rawData) : super(rawData);

  @override
  void sendNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(
        _domain, (newValue as bool) ? "turn_on" : "turn_off", entityId, null));
  }

  @override
  Widget _buildActionWidget(bool inCard, BuildContext context) {
    return Switch(
      value: this.isOn,
      onChanged: ((switchState) {
        sendNewState(switchState);
      }),
    );
  }
}
