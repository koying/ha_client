part of '../main.dart';

class _SelectEntityWidgetState extends _EntityWidgetState {
  List<String> _listOptions = [];

  @override
  void setNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(widget.entity.domain, "select_option", widget.entity.entityId,
        {"option": "$newValue"}));
  }

  @override
  Widget _buildActionWidget(BuildContext context) {
    _listOptions.clear();
    if (widget.entity._attributes["options"] != null) {
      widget.entity._attributes["options"].forEach((value){
        _listOptions.add(value.toString());
      });
    }
    return Expanded(
      //width: Entity.INPUT_WIDTH,
      child: DropdownButton<String>(
        value: widget.entity.state,
        items: this._listOptions.map((String value) {
          return new DropdownMenuItem<String>(
            value: value,
            child: new Text(value),
          );
        }).toList(),
        onChanged: (_) {
          setNewState(_);
        },
      ),
    );
  }
}