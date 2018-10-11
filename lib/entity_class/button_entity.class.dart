part of '../main.dart';

class _ButtonEntityWidgetState extends _EntityWidgetState {

  @override
  void setNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(widget.entity.domain, "turn_on", widget.entity.entityId, null));
  }

  @override
  Widget _buildActionWidget(BuildContext context) {
    return FlatButton(
      onPressed: (() {
        setNewState(null);
      }),
      child: Text(
        "EXECUTE",
        textAlign: TextAlign.right,
        style:
        new TextStyle(fontSize: stateFontSize, color: Colors.blue),
      ),
    );
  }
}