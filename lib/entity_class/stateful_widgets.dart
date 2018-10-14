part of '../main.dart';

class SwitchControlWidget extends StatefulWidget {
  @override
  _SwitchControlWidgetState createState() => _SwitchControlWidgetState();
}

class _SwitchControlWidgetState extends State<SwitchControlWidget> {

  @override
  void initState() {
    super.initState();
  }

  void _setNewState(newValue, Entity entity) {
    setState(() {
      entity.assumedState = newValue ? 'on' : 'off';
    });
    Timer(Duration(seconds: 2), (){
      setState(() {
        entity.assumedState = entity.state;
      });
    });
    eventBus.fire(new ServiceCallEvent(
        entity.domain, (newValue as bool) ? "turn_on" : "turn_off", entity.entityId, null));
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return Switch(
      value: entityModel.entity.assumedState == 'on',
      onChanged: ((switchState) {
        _setNewState(switchState, entityModel.entity);
      }),
    );
  }
}

class ButtonControlWidget extends StatefulWidget {
  @override
  _ButtonControlWidgetState createState() => _ButtonControlWidgetState();
}

class _ButtonControlWidgetState extends State<ButtonControlWidget> {

  @override
  void initState() {
    super.initState();
  }

  void _setNewState(Entity entity) {
    eventBus.fire(new ServiceCallEvent(entity.domain, "turn_on", entity.entityId, null));
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return FlatButton(
      onPressed: (() {
        _setNewState(entityModel.entity);
      }),
      child: Text(
        "EXECUTE",
        textAlign: TextAlign.right,
        style:
        new TextStyle(fontSize: entityModel.entity.stateFontSize, color: Colors.blue),
      ),
    );
  }
}

class TextControlWidget extends StatefulWidget {

  TextControlWidget({Key key}) : super(key: key);

  @override
  _TextControlWidgetState createState() => _TextControlWidgetState();
}

class _TextControlWidgetState extends State<TextControlWidget> {
  String _tmpValue;
  String _entityState;
  String _entityDomain;
  String _entityId;
  int _minLength;
  int _maxLength;
  FocusNode _focusNode = FocusNode();
  bool validValue = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_focusListener);
  }

  void setNewState(newValue, domain, entityId) {
    if (validate(newValue, _minLength, _maxLength)) {
      eventBus.fire(new ServiceCallEvent(domain, "set_value", entityId,
          {"value": "$newValue"}));
    } else {
      setState(() {
        _tmpValue = _entityState;
      });
    }
  }

  bool validate(newValue, minLength, maxLength) {
    if (newValue is String) {
      validValue = (newValue.length >= minLength) &&
          (maxLength == -1 ||
              (newValue.length <= maxLength));
    } else {
      validValue = true;
    }
    return validValue;
  }

  void _focusListener() {
    if (!_focusNode.hasFocus && (_tmpValue != _entityState)) {
      setNewState(_tmpValue, _entityDomain, _entityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final TextEntity entity = entityModel.entity;
    _entityState = entity.state;
    _entityDomain = entity.domain;
    _entityId = entity.entityId;
    _minLength = entity.valueMinLength;
    _maxLength = entity.valueMaxLength;

    if (!_focusNode.hasFocus && (_tmpValue != entity.state)) {
      _tmpValue = entity.state;
    }
    if (entity.isTextField || entity.isPasswordField) {
      return Expanded(
        //width: Entity.INPUT_WIDTH,
        child: TextField(
            focusNode: _focusNode,
            obscureText: entity.isPasswordField,
            controller: new TextEditingController.fromValue(
                new TextEditingValue(
                    text: _tmpValue,
                    selection:
                    new TextSelection.collapsed(offset: _tmpValue.length)
                )
            ),
            onChanged: (value) {
              _tmpValue = value;
            }),
      );
    } else {
      TheLogger.log("Warning", "Unsupported input mode for ${entity.entityId}");
      return SimpleEntityState();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_focusListener);
    _focusNode.dispose();
    super.dispose();
  }

}

class SliderControlWidget extends StatefulWidget {

  final bool expanded;

  SliderControlWidget({Key key, @required this.expanded}) : super(key: key);

  @override
  _SliderControlWidgetState createState() => _SliderControlWidgetState();
}

class _SliderControlWidgetState extends State<SliderControlWidget> {
  int _multiplier = 1;

  void setNewState(newValue, domain, entityId) {
    eventBus.fire(new ServiceCallEvent(domain, "set_value", entityId,
        {"value": "${newValue.toString()}"}));
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final SliderEntity entity = entityModel.entity;
    if (entity.valueStep < 1) {
      _multiplier = 10;
    } else if (entity.valueStep < 0.1) {
      _multiplier = 100;
    }
    Widget slider = Slider(
      min: entity.minValue * _multiplier,
      max: entity.maxValue * _multiplier,
      value: (entity.doubleState <= entity.maxValue) &&
          (entity.doubleState >= entity.minValue)
          ? entity.doubleState * _multiplier
          : entity.minValue * _multiplier,
      onChanged: (value) {
        setState(() {
          entity.state =
              (value.roundToDouble() / _multiplier).toString();
        });
        eventBus.fire(new StateChangedEvent(entity.entityId,
            (value.roundToDouble() / _multiplier).toString(), true));

      },
      onChangeEnd: (value) {
        setNewState(value.roundToDouble() / _multiplier, entity.domain, entity.entityId);
      },
    );
    if (widget.expanded) {
      return Expanded(
        child: slider,
      );
    } else {
      return slider;
    }
  }
}

class ClimateControlWidget extends StatefulWidget {

  ClimateControlWidget({Key key}) : super(key: key);

  @override
  _ClimateControlWidgetState createState() => _ClimateControlWidgetState();
}

class _ClimateControlWidgetState extends State<ClimateControlWidget> {

  bool _showPending = false;
  bool _changedHere = false;
  Timer _resetTimer;
  double _tmpTemperature = 0.0;
  String _tmpOperationMode = "";
  bool _tmpAwayMode = false;
  double _temperatureStep = 0.2;

  void _resetVars(ClimateEntity entity) {
    _tmpTemperature = entity.temperature;
    _tmpOperationMode = entity.operationMode;
    _tmpAwayMode = entity.awayMode;
    _showPending = false;
    _changedHere = false;
  }

  void _temperatureUp(ClimateEntity entity) {
    _tmpTemperature += _temperatureStep;
    _setTemperature(entity);
  }

  void _temperatureDown(ClimateEntity entity) {
    _tmpTemperature -= _temperatureStep;
    _setTemperature(entity);
  }

  void _setTemperature(ClimateEntity entity) {
    setState(() {
      _tmpTemperature = double.parse(_tmpTemperature.toStringAsFixed(1));
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_temperature", entity.entityId,{"temperature": "${_tmpTemperature.toStringAsFixed(1)}"}));
      _resetStateTimer(entity);
    });
  }

  void _setOperationMode(ClimateEntity entity, value) {
    setState(() {
      _tmpOperationMode = value;
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_operation_mode", entity.entityId,{"operation_mode": "$_tmpOperationMode"}));
      _resetStateTimer(entity);
    });
  }

  void _setAwayMode(ClimateEntity entity, value) {
    setState(() {
      _tmpAwayMode = value;
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_away_mode", entity.entityId,{"away_mode": "${_tmpAwayMode ? 'on' : 'off'}"}));
      _resetStateTimer(entity);
    });
  }

  void _resetStateTimer(ClimateEntity entity) {
    if (_resetTimer!=null) {
      _resetTimer.cancel();
    }
    _resetTimer = Timer(Duration(seconds: 3), () {
      setState(() {});
      _resetVars(entity);
    });
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final ClimateEntity entity = entityModel.entity;
    if (_changedHere) {
      _showPending = (_tmpTemperature != entity.temperature);
      _changedHere = false;
    } else {
      _resetTimer?.cancel();
      _resetVars(entity);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(entity.leftWidgetPadding, entity.rowPadding, entity.rightWidgetPadding, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Target temperature for ${_tmpOperationMode != 'off' ? _tmpOperationMode : ''}", style: TextStyle(
              fontSize: entity.stateFontSize
          )),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  "$_tmpTemperature",
                  style: TextStyle(
                      fontSize: entity.largeFontSize,
                      color: _showPending ? Colors.red : Colors.black
                  ),
                ),
              ),
              Column(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_up),
                    iconSize: 30.0,
                    onPressed: () => _temperatureUp(entity),
                  ),
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_down),
                    iconSize: 30.0,
                    onPressed: () => _temperatureDown(entity),
                  )
                ],
              )
            ],
          ),
          Text("Operation", style: TextStyle(
              fontSize: entity.stateFontSize
          )),
          DropdownButton<String>(
            value: "$_tmpOperationMode",
            iconSize: 30.0,
            style: TextStyle(
              fontSize: entity.largeFontSize,
              color: Colors.black,
            ),
            items: entity.operationList.map((String value) {
              return new DropdownMenuItem<String>(
                value: value,
                child: new Text(value),
              );
            }).toList(),
            onChanged: (mode) => _setOperationMode(entity, mode),
          ),
          Padding(
            padding: EdgeInsets.only(top: entity.rowPadding),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    "Away mode",
                    style: TextStyle(
                        fontSize: entity.stateFontSize
                    ),
                  ),
                ),
                Switch(
                  onChanged: (value) => _setAwayMode(entity, value),
                  value: _tmpAwayMode,
                )
              ],
            ),
          )
        ],
      ),
    );
  }


  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

}

class SelectControlWidget extends StatefulWidget {

  SelectControlWidget({Key key}) : super(key: key);

  @override
  _SelectControlWidgetState createState() => _SelectControlWidgetState();
}

class _SelectControlWidgetState extends State<SelectControlWidget> {

  void setNewState(domain, entityId, newValue) {
    eventBus.fire(new ServiceCallEvent(domain, "select_option", entityId,
        {"option": "$newValue"}));
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final SelectEntity entity = entityModel.entity;
    Widget ctrl;
    if (entity.listOptions.isNotEmpty) {
      ctrl = DropdownButton<String>(
        value: entity.state,
        items: entity.listOptions.map((String value) {
          return new DropdownMenuItem<String>(
            value: value,
            child: new Text(value),
          );
        }).toList(),
        onChanged: (_) {
          setNewState(entity.domain, entity.entityId,_);
        },
      );
    } else {
      ctrl = Text('---');
    }
    return Expanded(
      //width: Entity.INPUT_WIDTH,
      child: ctrl,
    );
  }


}