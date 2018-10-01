part of '../main.dart';

class SliderEntity extends Entity {
  int _multiplier = 1;

  double get minValue => _attributes["min"] ?? 0.0;
  double get maxValue => _attributes["max"] ?? 100.0;
  double get valueStep => _attributes["step"] ?? 1.0;
  double get doubleState => double.tryParse(_state) ?? 0.0;

  SliderEntity(Map rawData) : super(rawData) {
    if (valueStep < 1) {
      _multiplier = 10;
    } else if (valueStep < 0.1) {
      _multiplier = 100;
    }
  }

  @override
  void sendNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(_domain, "set_value", _entityId,
        {"value": "${newValue.toString()}"}));
  }

  @override
  Widget _buildActionWidget(bool inCard, BuildContext context) {
    return Container(
      width: 200.0,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Slider(
              min: this.minValue * _multiplier,
              max: this.maxValue * _multiplier,
              value: (this.doubleState <= this.maxValue) &&
                  (this.doubleState >= this.minValue)
                  ? this.doubleState * _multiplier
                  : this.minValue * _multiplier,
              onChanged: (value) {
                eventBus.fire(new StateChangedEvent(_entityId,
                    (value.roundToDouble() / _multiplier).toString(), true));
              },
              onChangeEnd: (value) {
                sendNewState(value.roundToDouble() / _multiplier);
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: Entity.RIGHT_WIDGET_PADDING),
            child: Text("$_state${this.unitOfMeasurement}",
                textAlign: TextAlign.right,
                style: new TextStyle(
                  fontSize: Entity.STATE_FONT_SIZE,
                )),
          )
        ],
      ),
    );
  }
}