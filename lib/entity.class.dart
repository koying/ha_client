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
  static const INPUT_WIDTH = 160.0;

  Map _attributes;
  String _domain;
  String _entityId;
  String _state;
  DateTime _lastUpdated;

  String get displayName =>
      _attributes["friendly_name"] ?? (_attributes["name"] ?? "_");
  String get domain => _domain;
  String get entityId => _entityId;
  String get state => _state;
  set state(value) => _state = value;

  String get deviceClass => _attributes["device_class"] ?? null;
  bool get isView =>
      (_domain == "group") &&
      (_attributes != null ? _attributes["view"] ?? false : false);
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

  Widget buildWidget(bool inCard, BuildContext context) {
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
          _buildActionWidget(inCard, context)
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
      child: MaterialDesignIcons.createIconWidgetFromEntityData(
          this,
          Entity.ICON_SIZE,
          Entity.STATE_ICONS_COLORS[_state] ?? Colors.blueGrey),
    );
  }

  Widget _buildLastUpdatedWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Entity.LEFT_WIDGET_PADDING, Entity.SMALL_FONT_SIZE, 0.0, 0.0),
      child: Text(
        '${this.lastUpdated}',
        textAlign: TextAlign.left,
        style:
            TextStyle(fontSize: Entity.SMALL_FONT_SIZE, color: Colors.black26),
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
        style: TextStyle(fontSize: Entity.NAME_FONT_SIZE),
      ),
    );
  }

  Widget _buildActionWidget(bool inCard, BuildContext context) {
    return Padding(
        padding:
            EdgeInsets.fromLTRB(0.0, 0.0, Entity.RIGHT_WIDGET_PADDING, 0.0),
        child: GestureDetector(
          child: Text(
              "$_state${this.unitOfMeasurement}",
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: Entity.STATE_FONT_SIZE,
              )),
          onTap: openEntityPage,
        )
    );
  }
}

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

class ButtonEntity extends Entity {
  ButtonEntity(Map rawData) : super(rawData);

  @override
  void sendNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(_domain, "turn_on", _entityId, null));
  }

  @override
  Widget _buildActionWidget(bool inCard, BuildContext context) {
    return FlatButton(
      onPressed: (() {
        sendNewState(null);
      }),
      child: Text(
        "EXECUTE",
        textAlign: TextAlign.right,
        style:
            new TextStyle(fontSize: Entity.STATE_FONT_SIZE, color: Colors.blue),
      ),
    );
  }
}

//
//    SLIDER
//
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

//
//    DATETIME
//

class DateTimeEntity extends Entity {
  bool get hasDate => _attributes["has_date"] ?? false;
  bool get hasTime => _attributes["has_time"] ?? false;
  int get year => _attributes["year"] ?? 1970;
  int get month => _attributes["month"] ?? 1;
  int get day => _attributes["day"] ?? 1;
  int get hour => _attributes["hour"] ?? 0;
  int get minute => _attributes["minute"] ?? 0;
  int get second => _attributes["second"] ?? 0;
  String get formattedState => _getFormattedState();
  DateTime get dateTimeState => _getDateTimeState();

  DateTimeEntity(Map rawData) : super(rawData);

  DateTime _getDateTimeState() {
    return DateTime(this.year, this.month, this.day, this.hour, this.minute, this.second);
  }

  String _getFormattedState() {
    String formattedState = "";
    if (this.hasDate) {
      formattedState += formatDate(dateTimeState, [M, ' ', d, ', ', yyyy]);
    }
    if (this.hasTime) {
      formattedState += " "+formatDate(dateTimeState, [HH, ':', nn]);
    }
    return formattedState;
  }

  @override
  void sendNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(_domain, "set_datetime", _entityId,
        newValue));
  }

  @override
  Widget _buildActionWidget(bool inCard, BuildContext context) {
    return Padding(
        padding:
        EdgeInsets.fromLTRB(0.0, 0.0, Entity.RIGHT_WIDGET_PADDING, 0.0),
        child: GestureDetector(
          child: Text(
              "$formattedState",
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: Entity.STATE_FONT_SIZE,
              )),
          onTap: () => _handleStateTap(context),
        )
    );
  }

  void _handleStateTap(BuildContext context) {
    if (hasDate) {
      _showDatePicker(context).then((date) {
        if (date != null) {
          if (hasTime) {
            _showTimePicker(context).then((time){
              sendNewState({"date": "${formatDate(date, [yyyy, '-', mm, '-', dd])}", "time": "${formatDate(DateTime(1970, 1, 1, time.hour, time.minute), [HH, ':', nn])}"});
            });
          } else {
            sendNewState({"date": "${formatDate(date, [yyyy, '-', mm, '-', dd])}"});
          }
        }
      });
    } else if (hasTime) {
      _showTimePicker(context).then((time){
        if (time != null) {
          sendNewState({"time": "${formatDate(DateTime(1970, 1, 1, time.hour, time.minute), [HH, ':', nn])}"});
        }
      });
    } else {
      TheLogger.log("Warning", "$entityId has no date and no time");
    }
  }
  
  Future _showDatePicker(BuildContext context) {
    return showDatePicker(
        context: context,
        initialDate: dateTimeState,
        firstDate: DateTime(1970),
        lastDate: DateTime(2037) //Unix timestamp will finish at Jan 19, 2038
    );
  }

  Future _showTimePicker(BuildContext context) {
    return showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(dateTimeState)
    );
  }
}

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

class TextEntity extends Entity {
  String tmpState;
  FocusNode _focusNode;
  bool validValue = false;

  int get valueMinLength => _attributes["min"] ?? -1;
  int get valueMaxLength => _attributes["max"] ?? -1;
  String get valuePattern => _attributes["pattern"] ?? null;
  bool get isTextField => _attributes["mode"] == "text";
  bool get isPasswordField => _attributes["mode"] == "password";

  TextEntity(Map rawData) : super(rawData) {
    _focusNode = FocusNode();
    //TODO possible memory leak generator
    _focusNode.addListener(_focusListener);
    //tmpState = state;
  }

  @override
  void sendNewState(newValue) {
    if (validate(newValue)) {
      eventBus.fire(new ServiceCallEvent(_domain, "set_value", _entityId,
          {"value": "{newValue"}));
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
      validValue = (newValue.length >= this.valueMinLength) &&
          (this.valueMaxLength == -1 ||
              (newValue.length <= this.valueMaxLength));
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
  Widget _buildActionWidget(bool inCard, BuildContext context) {
    if (this.isTextField || this.isPasswordField) {
      return Container(
        width: Entity.INPUT_WIDTH,
        child: TextField(
            focusNode: inCard ? _focusNode : null,
            obscureText: this.isPasswordField,
            controller: new TextEditingController.fromValue(
                new TextEditingValue(
                    text: tmpState,
                    selection:
                        new TextSelection.collapsed(offset: tmpState.length))),
            onChanged: (value) {
              tmpState = value;
            }),
      );
    } else {
      TheLogger.log("Warning", "Unsupported input mode for $entityId");
      return super._buildActionWidget(inCard, context);
    }
  }
}
