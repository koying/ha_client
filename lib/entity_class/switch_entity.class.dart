part of '../main.dart';

class _SwitchEntityWidgetState extends _EntityWidgetState {

  @override
  void initState() {
    super.initState();
  }

  @override
  void setNewState(newValue) {
    setState(() {
      widget.entity.assumedState = newValue ? 'on' : 'off';
    });
    Timer(Duration(seconds: 2), (){
      setState(() {
        widget.entity.assumedState = widget.entity.state;
      });
    });
    eventBus.fire(new ServiceCallEvent(
        widget.entity.domain, (newValue as bool) ? "turn_on" : "turn_off", widget.entity.entityId, null));
  }

  @override
  Widget _buildActionWidget(BuildContext context) {
    return Switch(
      value: widget.entity.assumedState == 'on',
      onChanged: ((switchState) {
        setNewState(switchState);
      }),
    );
  }
}
