part of 'main.dart';

class Entity {
  static const STATE_ICONS_COLORS = {
    "on": Colors.amber,
    "off": Color.fromRGBO(68, 115, 158, 1.0),
    "unavailable": Colors.black12,
    "unknown": Colors.black12,
    "playing": Colors.amber
  };
  static const RIGHT_WIDGET_PADDING = 14.0;
  static const LEFT_WIDGET_PADDING = 8.0;
  static const EXTENDED_WIDGET_HEIGHT = 50.0;
  static const WIDGET_HEIGHT = 34.0;
  static const ICON_SIZE = 28.0;
  static const STATE_FONT_SIZE = 16.0;
  static const NAME_FONT_SIZE = 16.0;
  static const SMALL_FONT_SIZE = 14.0;

  Map _attributes;
  String _domain;
  String _entityId;
  String _state;
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
  int get valueMinLength => _attributes["min"] ?? -1;
  int get valueMaxLength => _attributes["max"] ?? -1;
  String get valuePattern => _attributes["pattern"] ?? null;
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
      DateTime now = DateTime.now();
      Duration d = now.difference(_lastUpdated);
      String text;
      int v;
      if (d.inDays == 0) {
        if (d.inHours == 0) {
          if (d.inMinutes == 0) {
            text = "seconds ago";
            v = d.inSeconds;
          } else {
            text = "minutes ago";
            v = d.inMinutes;
          }
        } else {
          text = "hours ago";
          v = d.inHours;
        }
      } else {
        text = "days ago";
        v = d.inDays;
      }
      return "$v $text";
    }
  }

  void openEntityPage() {
    eventBus.fire(new ShowEntityPageEvent(this));
  }

  void sendNewState(newState) {
    return;
  }

  Widget buildWidget(bool inCard) {
    return SizedBox(
      height: Entity.WIDGET_HEIGHT,
      child: Row(
        children: <Widget>[
          GestureDetector(
            child: _buildIconWidget(),
            onTap: inCard ? openEntityPage : null,
          ),
          Expanded(
            child: GestureDetector(
              child: _buildNameWidget(),
              onTap: inCard ? openEntityPage : null,
            ),
          ),
          _buildActionWidget(inCard)
        ],
      ),
    );
  }

  Widget buildAdditionalWidget() {
    return _buildLastUpdatedWidget();
  }

  Widget _buildIconWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(Entity.LEFT_WIDGET_PADDING, 0.0, 12.0, 0.0),
      child: MaterialDesignIcons.createIconWidgetFromEntityData(this, Entity.ICON_SIZE, Entity.STATE_ICONS_COLORS[_state] ?? Colors.blueGrey),
    );
  }

  Widget _buildLastUpdatedWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(Entity.LEFT_WIDGET_PADDING, Entity.SMALL_FONT_SIZE, 0.0, 0.0),
      child: Text(
        '${this.lastUpdated}',
        textAlign: TextAlign.left,
        style: TextStyle(
            fontSize: Entity.SMALL_FONT_SIZE,
            color: Colors.black26
        ),
      ),
    );
  }

  Widget _buildNameWidget() {
    return Padding(
      padding: EdgeInsets.only(right: 10.0),
      child: Text(
        "${this.displayName}",
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: TextStyle(
            fontSize: Entity.NAME_FONT_SIZE
        ),
      ),
    );
  }

  Widget _buildActionWidget(bool inCard) {
    return Padding(
        padding: EdgeInsets.fromLTRB(0.0, 0.0, Entity.RIGHT_WIDGET_PADDING, 0.0),
        child: GestureDetector(
          child: Text(
              this.isPasswordField ? "******" :
              "$_state${this.unitOfMeasurement}",
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: Entity.STATE_FONT_SIZE,
              )
          ),
          onTap: openEntityPage,
        )
    );
  }

  /*Widget _buildExtendedActionWidget(BuildContext context, String staticState) {
    return _buildActionWidget(context);
  }*/
}

class SwitchEntity extends Entity {

  SwitchEntity(Map rawData) : super(rawData);

  @override
  void sendNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(_domain, (newValue as bool) ? "turn_on" : "turn_off", entityId, null));
  }

  @override
  Widget _buildActionWidget(bool inCard) {
    return Switch(
      value: this.isOn,
      onChanged: ((switchState) {
        sendNewState(switchState);
      }),
    );
  }

}

class ButtonEntity extends Entity {

  ButtonEntity(Map rawData) : super(rawData);

  @override
  void sendNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(_domain, "turn_on", _entityId, null));
  }

  @override
  Widget _buildActionWidget(bool inCard) {
    return FlatButton(
      onPressed: (() {
        sendNewState(null);
      }),
      child: Text(
        "EXECUTE",
        textAlign: TextAlign.right,
        style: new TextStyle(fontSize: Entity.STATE_FONT_SIZE, color: Colors.blue),
      ),
    );
  }

}

class InputEntity extends Entity {
  String tmpState;
  FocusNode _focusNode;
  bool validValue = false;

  InputEntity(Map rawData) : super(rawData) {
    _focusNode = FocusNode();
    //TODO possible memory leak generator
    _focusNode.addListener(_focusListener);
    //tmpState = state;
  }

  @override
  void sendNewState(newValue) {
    if (validate(newValue)) {
      eventBus.fire(new ServiceCallEvent(_domain, "set_value", _entityId,
          {"value": "${newValue.toString()}"}));
    }
  }

  @override
  void update(Map rawData) {
    super.update(rawData);
    tmpState = _state;
  }

  bool validate(newValue) {
    if (newValue is String) {
      //TODO add pattern support
      validValue = (newValue.length >= this.valueMinLength) && (this.valueMaxLength == -1 || (newValue.length <= this.valueMaxLength));
    } else {
      validValue = true;
    }
    return validValue;
  }

  void _focusListener() {
    if (!_focusNode.hasFocus && (tmpState != state)) {
      sendNewState(tmpState);
      tmpState = state;
    }
  }

  @override
  Widget _buildActionWidget(bool inCard) {
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
                onChanged: (value) {
                  if (validate(value.roundToDouble() / 10)) {
                    eventBus.fire(new StateChangedEvent(
                        _entityId, (value.roundToDouble() / 10).toString(),
                        true));
                  }
                },
                onChangeEnd: (value) {
                  sendNewState(value.roundToDouble() / 10);
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: Entity.RIGHT_WIDGET_PADDING),
              child: Text(
                  "$_state${this.unitOfMeasurement}",
                  textAlign: TextAlign.right,
                  style: new TextStyle(
                    fontSize: Entity.STATE_FONT_SIZE,
                  )
              ),
            )
          ],
        ),
      );
    } else if (this.isTextField || this.isPasswordField) {
      return Container(
        width: 160.0,
        child: TextField(
          focusNode: inCard ? _focusNode : null,
          obscureText: this.isPasswordField,
          controller: new TextEditingController.fromValue(new TextEditingValue(text: tmpState,selection: new TextSelection.collapsed(offset: tmpState.length))),
          onChanged: (value) {
            tmpState = value;
          }
        ),
      );
    } else {
      return super._buildActionWidget(inCard);
    }
  }

}