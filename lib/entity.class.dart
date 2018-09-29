part of 'main.dart';

class Entity {
  static const STATE_ICONS_COLORS = {
    "on": Colors.amber,
    "off": Color.fromRGBO(68, 115, 158, 1.0),
    "unavailable": Colors.black12,
    "unknown": Colors.black12,
    "playing": Colors.amber
  };
  static const RIGTH_WIDGET_PADDING = 14.0;
  static const LEFT_WIDGET_PADDING = 8.0;
  static const EXTENDED_WIDGET_HEIGHT = 50.0;
  static const WIDGET_HEIGHT = 34.0;

  Map _attributes;
  String _domain;
  String _entityId;
  String _state;
  String _entityPicture;
  DateTime _lastUpdated;

  String get displayName => _attributes["friendly_name"] ?? (_attributes["name"] ?? "_");
  String get domain => _domain;
  String get entityId => _entityId;
  String get state => _state;
  set state(value) => _state = value;

  double get minValue => _attributes["min"] ?? 0.0;
  double get maxValue => _attributes["max"] ?? 100.0;
  double get valueStep => _attributes["step"] ?? 1.0;
  double get doubleState => double.tryParse(_state) ?? 0.0;
  bool get isSliderField => _attributes["mode"] == "slider";
  bool get isTextField => _attributes["mode"] == "text";
  bool get isPasswordField => _attributes["mode"] == "password";

  String get deviceClass => _attributes["device_class"] ?? null;
  bool get isView => (_domain == "group") && (_attributes != null ? _attributes["view"] ?? false : false);
  bool get isGroup => _domain == "group";
  String get icon => _attributes["icon"] ?? "";
  bool get isOn => state == "on";
  String get entityPicture => _attributes["entity_picture"];
  String get unitOfMeasurement => _attributes["unit_of_measurement"] ?? "";
  List get childEntities => _attributes["entity_id"] ?? [];
  String get lastUpdated => _getLastUpdatedFormatted();

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
    _lastUpdated = DateTime.tryParse(rawData["last_updated"]);
  }

  String _getLastUpdatedFormatted() {
    if (_lastUpdated == null) {
      return "-";
    } else {
      return formatDate(_lastUpdated, [yy, '-', M, '-', d, ' ', HH, ':', nn, ':', ss]);
    }
  }

  void openEntityPage() {
    eventBus.fire(new ShowEntityPageEvent(this));
  }

  Widget buildWidget() {
    return SizedBox(
      height: Entity.WIDGET_HEIGHT,
      child: Row(
        children: <Widget>[
          GestureDetector(
            child: _buildIconWidget(),
            onTap: openEntityPage,
          ),
          Expanded(
            child: GestureDetector(
              child: _buildNameWidget(),
              onTap: openEntityPage,
            ),
          ),
          _buildActionWidget()
        ],
      ),
    );
  }

  Widget buildExtendedWidget(String staticState) {
    return Row(
      children: <Widget>[
        _buildIconWidget(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: _buildNameWidget(),
                  ),
                  _buildExtendedActionWidget(staticState)
                ],
              ),
              _buildLastUpdatedWidget()
            ],
          ),
        )
      ],
    );
  }

  Widget _buildIconWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(Entity.LEFT_WIDGET_PADDING, 0.0, 12.0, 0.0),
      child: MaterialDesignIcons.createIconWidgetFromEntityData(this, 28.0, Entity.STATE_ICONS_COLORS[_state] ?? Colors.blueGrey),
    );
  }

  Widget _buildLastUpdatedWidget() {
    return Text(
      '${this.lastUpdated}',
      textAlign: TextAlign.left,
      style: TextStyle(
          fontSize: 12.0,
          color: Colors.black26
      ),
    );
  }

  Widget _buildNameWidget() {
    return Text(
      "${this.displayName}",
      overflow: TextOverflow.fade,
      softWrap: false,
      style: TextStyle(
          fontSize: 16.0
      ),
    );
  }

  Widget _buildActionWidget() {
    return Padding(
        padding: EdgeInsets.fromLTRB(0.0, 0.0, Entity.RIGTH_WIDGET_PADDING, 0.0),
        child: GestureDetector(
          child: Text(
              this.isPasswordField ? "******" :
              "$_state${this.unitOfMeasurement}",
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 16.0,
              )
          ),
          onTap: openEntityPage,
        )
    );
  }

  Widget _buildExtendedActionWidget(String staticState) {
    return _buildActionWidget();
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
  Widget buildExtendedWidget(String staticState) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: Entity.EXTENDED_WIDGET_HEIGHT,
          child: Row(
            children: <Widget>[
              _buildIconWidget(),
              Expanded(
                child: _buildNameWidget(),
              ),
              _buildLastUpdatedWidget()
            ],
          ),
        ),
        SizedBox(
          height: Entity.EXTENDED_WIDGET_HEIGHT,
          child: _buildExtendedActionWidget(staticState),
        )
      ],
    );
  }

  @override
  Widget _buildActionWidget() {
    if (this.isSliderField) {
      return Container(
        width: 200.0,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Slider(
                min: this.minValue*10,
                max: this.maxValue*10,
                value: (this.doubleState <= this.maxValue) && (this.doubleState >= this.minValue) ? this.doubleState*10 : this.minValue*10,
                divisions: this.getValueDivisions(),
                onChanged: (value) {
                  eventBus.fire(new StateChangedEvent(_entityId, (value.roundToDouble() / 10).toString(), true));
                },
                onChangeEnd: (value) {
                  eventBus.fire(new ServiceCallEvent(_domain, "set_value", _entityId,{"value": "$_state"}));
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
      return super._buildActionWidget();
    }
  }

  @override
  Widget _buildExtendedActionWidget(String staticState) {
    return Padding(
        padding: EdgeInsets.fromLTRB(Entity.LEFT_WIDGET_PADDING, 0.0, Entity.RIGTH_WIDGET_PADDING, 0.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: TextField(
                obscureText: this.isPasswordField,
                controller: TextEditingController(
                  text: staticState,
                ),
                onChanged: (value) {
                  staticState = value;
                },
              ),
            ),
            SizedBox(
              width: 63.0,
              child: FlatButton(
                onPressed: () {
                  eventBus.fire(new ServiceCallEvent(_domain, "set_value", _entityId,{"value": "$staticState"}));
                },
                child: Text(
                    "SET",
                    textAlign: TextAlign.right,
                  style: new TextStyle(fontSize: 16.0, color: Colors.blue),
                ),
              ),
            )
          ],
        )
    );
  }

}