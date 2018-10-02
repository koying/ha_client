part of '../main.dart';

class _SwitchEntityWidgetState extends _EntityWidgetState {

  @override
  void initState() {
    super.initState();
  }

  @override
  void sendNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(
        widget.entity.domain, (newValue as bool) ? "turn_on" : "turn_off", widget.entity.entityId, null));
  }

  @override
  Widget _buildActionWidget(bool inCard, BuildContext context) {
    return Switch(
      value: widget.entity.isOn,
      onChanged: ((switchState) {
        sendNewState(switchState);
        setState(() {
          widget.entity.state = switchState ? 'on' : 'off';
        });
      }),
    );
  }
}
