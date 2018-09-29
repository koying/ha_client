part of 'main.dart';

class Entity {
  static Map<String, Color> stateIconColors = {
    "on": Colors.amber,
    "off": Color.fromRGBO(68, 115, 158, 1.0),
    "unavailable": Colors.black12,
    "unknown": Colors.black12,
    "playing": Colors.amber
  };
  Map _attributes;
  String _domain;
  String _entityId;
  String _state;
  String _entityPicture;

  String get displayName => _attributes["friendly_name"] ?? (_attributes["name"] ?? "_");
  String get domain => _domain;
  String get entityId => _entityId;
  String get state => _state;
  set state(value) => _state = value;

  double get minValue => _attributes["min"] ?? 0.0;
  double get maxValue => _attributes["max"] ?? 100.0;
  double get valueStep => _attributes["step"] ?? 1.0;
  double get doubleState => double.tryParse(_state) ?? 0.0;
  bool get isSlider => _attributes["mode"] == "slider";

  String get deviceClass => _attributes["device_class"] ?? null;
  bool get isView => (_domain == "group") && (_attributes != null ? _attributes["view"] ?? false : false);
  bool get isGroup => _domain == "group";
  String get icon => _attributes["icon"] ?? "";
  bool get isOn => state == "on";
  String get entityPicture => _attributes["entity_picture"];
  String get unitOfMeasurement => _attributes["unit_of_measurement"] ?? "";
  List get childEntities => _attributes["entity_id"] ?? [];

  Entity(Map rawData) {
    update(rawData);
  }

  int getValueDivisions() {
    return ((maxValue - minValue)/valueStep).round().round();
  }

  void update(Map rawData) {
    _attributes = rawData["attributes"] ?? {};
    _domain = rawData["entity_id"].split(".")[0];
    _entityId = rawData["entity_id"];
    _state = rawData["state"];
  }

  Widget buildWidget() {
    return SizedBox(
      height: 34.0,
      child: Row(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(8.0, 0.0, 12.0, 0.0),
            child: MaterialDesignIcons.createIconWidgetFromEntityData(this, 28.0, Entity.stateIconColors[_state] ?? Colors.blueGrey),
          ),
          Expanded(
            child: Text(
              "${this.displayName}",
              overflow: TextOverflow.fade,
              softWrap: false,
              style: TextStyle(
                  fontSize: 16.0
              ),
            ),
          ),
          _buildActionWidget()
        ],
      ),
    );
  }

  Widget _buildActionWidget() {
    return Padding(
        padding: EdgeInsets.fromLTRB(0.0, 0.0, 14.0, 0.0),
        child: Text(
            "${_state}${this.unitOfMeasurement}",
            textAlign: TextAlign.right,
            style: new TextStyle(
              fontSize: 16.0,
            )
        )
    );
  }
}

class SwitchEntity extends Entity {

  SwitchEntity(Map rawData) : super(rawData);

  @override
  Widget _buildActionWidget() {
    return Switch(
      value: this.isOn,
      onChanged: ((switchState) {
        eventBus.fire(new ServiceCallEvent(_domain, switchState ? "turn_on" : "turn_off", entityId, null));
      }),
    );
  }

}

class ButtonEntity extends Entity {

  ButtonEntity(Map rawData) : super(rawData);

  @override
  Widget _buildActionWidget() {
    return FlatButton(
      onPressed: (() {
        eventBus.fire(new ServiceCallEvent(_domain, "turn_on", _entityId, null));
      }),
      child: Text(
        "EXECUTE",
        textAlign: TextAlign.right,
        style: new TextStyle(fontSize: 16.0, color: Colors.blue),
      ),
    );
  }

}

class InputEntity extends Entity {

  InputEntity(Map rawData) : super(rawData);

  @override
  Widget _buildActionWidget() {
    if (this.isSlider) {
      return Container(
        width: 200.0,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Slider(
                min: this.minValue*10,
                max: this.maxValue*10,
                value: this.doubleState*10,
                divisions: this.getValueDivisions(),
                onChanged: (value) {
                  eventBus.fire(new StateChangedEvent(_entityId, (value.roundToDouble() / 10).toString(), true));
                },
                onChangeEnd: (value) {
                  eventBus.fire(new ServiceCallEvent(_domain, "set_value", _entityId,{"value": "${_state}"}));
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Text(
                  "${_state}${this.unitOfMeasurement}",
                  textAlign: TextAlign.right,
                  style: new TextStyle(
                    fontSize: 16.0,
                  )
              ),
            )
          ],
        ),
      );
    } else {
      //TODO draw box instead of slider
      return Text("Not implemented");
    }
  }

}