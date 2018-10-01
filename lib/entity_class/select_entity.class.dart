part of '../main.dart';

class SelectEntity extends Entity {
  List<String> _listOptions = [];
  String get initialValue => _attributes["initial"] ?? null;

  SelectEntity(Map rawData) : super(rawData) {
    if (_attributes["options"] != null) {
      _attributes["options"].forEach((value){
        _listOptions.add(value.toString());
      });
    }
  }

  @override
  void sendNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(_domain, "select_option", _entityId,
        {"option": "$newValue"}));
  }

  @override
  Widget _buildActionWidget(bool inCard, BuildContext context) {
    return Container(
      width: Entity.INPUT_WIDTH,
      child: DropdownButton<String>(
        value: _state,
        items: this._listOptions.map((String value) {
          return new DropdownMenuItem<String>(
            value: value,
            child: new Text(value),
          );
        }).toList(),
        onChanged: (_) {
          sendNewState(_);
        },
      ),
    );
  }
}