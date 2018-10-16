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
  double _tmpTargetLow = 0.0;
  double _tmpTargetHigh = 0.0;
  double _tmpTargetHumidity = 0.0;
  String _tmpOperationMode;
  String _tmpFanMode;
  String _tmpSwingMode;
  bool _tmpAwayMode = false;
  bool _tmpIsOff = false;
  bool _tmpAuxHeat = false;

  void _resetVars(ClimateEntity entity) {
    _tmpTemperature = entity.temperature;
    _tmpTargetHigh = entity.targetHigh;
    _tmpTargetLow = entity.targetLow;
    _tmpOperationMode = entity.operationMode;
    _tmpFanMode = entity.fanMode;
    _tmpSwingMode = entity.swingMode;
    _tmpAwayMode = entity.awayMode;
    _tmpIsOff = entity.isOff;
    _tmpAuxHeat = entity.auxHeat;
    _tmpTargetHumidity = entity.targetHumidity;

    _showPending = false;
    _changedHere = false;
  }

  void _temperatureUp(ClimateEntity entity, double step) {
    _tmpTemperature = ((_tmpTemperature + step) <= entity.maxTemp) ? _tmpTemperature + step : entity.maxTemp;
    _setTemperature(entity);
  }

  void _temperatureDown(ClimateEntity entity, double step) {
    _tmpTemperature = ((_tmpTemperature - step) >= entity.minTemp) ? _tmpTemperature - step : entity.minTemp;
    _setTemperature(entity);
  }

  void _targetLowUp(ClimateEntity entity, double step) {
    _tmpTargetLow = ((_tmpTargetLow + step) <= entity.maxTemp) ? _tmpTargetLow + step : entity.maxTemp;
    _setTargetTemp(entity);
  }

  void _targetLowDown(ClimateEntity entity, double step) {
    _tmpTargetLow = ((_tmpTargetLow - step) >= entity.minTemp) ? _tmpTargetLow - step : entity.minTemp;
    _setTargetTemp(entity);
  }

  void _targetHighUp(ClimateEntity entity, double step) {
    _tmpTargetHigh = ((_tmpTargetHigh + step) <= entity.maxTemp) ? _tmpTargetHigh + step : entity.maxTemp;
    _setTargetTemp(entity);
  }

  void _targetHighDown(ClimateEntity entity, double step) {
    _tmpTargetHigh = ((_tmpTargetHigh - step) >= entity.minTemp) ? _tmpTargetHigh - step : entity.minTemp;
    _setTargetTemp(entity);
  }

  void _setTemperature(ClimateEntity entity) {
    setState(() {
      _tmpTemperature = double.parse(_tmpTemperature.toStringAsFixed(1));
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_temperature", entity.entityId,{"temperature": "${_tmpTemperature.toStringAsFixed(1)}"}));
      _resetStateTimer(entity);
    });
  }

  void _setTargetTemp(ClimateEntity entity) {
    setState(() {
      _tmpTargetLow = double.parse(_tmpTargetLow.toStringAsFixed(1));
      _tmpTargetHigh = double.parse(_tmpTargetHigh.toStringAsFixed(1));
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_temperature", entity.entityId,{"target_temp_high": "${_tmpTargetHigh.toStringAsFixed(1)}", "target_temp_low": "${_tmpTargetLow.toStringAsFixed(1)}"}));
      _resetStateTimer(entity);
    });
  }

  void _setTargetHumidity(ClimateEntity entity, double value) {
    setState(() {
      _tmpTargetHumidity = value.roundToDouble();
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_humidity", entity.entityId,{"humidity": "$_tmpTargetHumidity"}));
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

  void _setSwingMode(ClimateEntity entity, value) {
    setState(() {
      _tmpSwingMode = value;
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_swing_mode", entity.entityId,{"swing_mode": "$_tmpSwingMode"}));
      _resetStateTimer(entity);
    });
  }

  void _setFanMode(ClimateEntity entity, value) {
    setState(() {
      _tmpFanMode = value;
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_fan_mode", entity.entityId,{"fan_mode": "$_tmpFanMode"}));
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

  void _setOnOf(ClimateEntity entity, value) {
    setState(() {
      _tmpIsOff = !value;
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "${_tmpIsOff ? 'turn_off' : 'turn_on'}", entity.entityId, null));
      _resetStateTimer(entity);
    });
  }

  void _setAuxHeat(ClimateEntity entity, value) {
    setState(() {
      _tmpAuxHeat = value;
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_aux_heat", entity.entityId, {"aux_heat": "$_tmpAuxHeat"}));
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
          _buildOnOffControl(entity),
          _buildTemperatureControls(entity),
          _buildHumidityControls(entity),
          _buildOperationControl(entity),
          _buildFanControl(entity),
          _buildSwingControl(entity),
          _buildAwayModeControl(entity),
          _buildAuxHeatControl(entity)
        ],
      ),
    );
  }

  Widget _buildAwayModeControl(ClimateEntity entity) {
    if (entity.supportAwayMode) {
      return Row(
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
      );
    } else {
      return Container(height: 0.0, width: 0.0,);
    }
  }

  Widget _buildOnOffControl(ClimateEntity entity) {
    if (entity.supportOnOff) {
      return Row(
        children: <Widget>[
          Expanded(
            child: Text(
              "On / Off",
              style: TextStyle(
                  fontSize: entity.stateFontSize
              ),
            ),
          ),
          Switch(
            onChanged: (value) => _setOnOf(entity, value),
            value: !_tmpIsOff,
          )
        ],
      );
    } else {
      return Container(height: 0.0, width: 0.0,);
    }
  }

  Widget _buildAuxHeatControl(ClimateEntity entity) {
    if (entity.supportAuxHeat ) {
      return Row(
        children: <Widget>[
          Expanded(
            child: Text(
              "Aux heat",
              style: TextStyle(
                  fontSize: entity.stateFontSize
              ),
            ),
          ),
          Switch(
            onChanged: (value) => _setAuxHeat(entity, value),
            value: _tmpAuxHeat,
          )
        ],
      );
    } else {
      return Container(height: 0.0, width: 0.0,);
    }
  }

  Widget _buildOperationControl(ClimateEntity entity) {
    if (entity.supportOperationMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
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
          Container(height: entity.rowPadding,)
        ],
      );
    } else {
      return Container(height: 0.0, width: 0.0);
    }
  }

  Widget _buildFanControl(ClimateEntity entity) {
    if (entity.supportFanMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Fan mode", style: TextStyle(
              fontSize: entity.stateFontSize
          )),
          DropdownButton<String>(
            value: "$_tmpFanMode",
            iconSize: 30.0,
            style: TextStyle(
              fontSize: entity.largeFontSize,
              color: Colors.black,
            ),
            items: entity.fanList.map((String value) {
              return new DropdownMenuItem<String>(
                value: value,
                child: new Text(value),
              );
            }).toList(),
            onChanged: (mode) => _setFanMode(entity, mode),
          ),
          Container(height: entity.rowPadding,)
        ],
      );
    } else {
      return Container(height: 0.0, width: 0.0);
    }
  }

  Widget _buildSwingControl(ClimateEntity entity) {
    if (entity.supportSwingMode) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Swing mode", style: TextStyle(
              fontSize: entity.stateFontSize
          )),
          DropdownButton<String>(
            value: "$_tmpSwingMode",
            iconSize: 30.0,
            style: TextStyle(
              fontSize: entity.largeFontSize,
              color: Colors.black,
            ),
            items: entity.swingList.map((String value) {
              return new DropdownMenuItem<String>(
                value: value,
                child: new Text(value),
              );
            }).toList(),
            onChanged: (mode) => _setSwingMode(entity, mode),
          ),
          Container(height: entity.rowPadding,)
        ],
      );
    } else {
      return Container(height: 0.0, width: 0.0);
    }
  }

  Widget _buildTemperatureControls(ClimateEntity entity) {
    List<Widget> result = [];
    if (entity.supportTargetTemperature) {
      result.addAll(<Widget>[
        Text(
          "$_tmpTemperature",
          style: TextStyle(
              fontSize: entity.largeFontSize,
              color: _showPending ? Colors.red : Colors.black
          ),
        ),
        Column(
          children: <Widget>[
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName('mdi:chevron-up')),
              iconSize: 30.0,
              onPressed: () => _temperatureUp(entity, 0.1),
            ),
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName('mdi:chevron-down')),
              iconSize: 30.0,
              onPressed: () => _temperatureDown(entity, 0.1),
            )
          ],
        ),
        Column(
          children: <Widget>[
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName('mdi:chevron-double-up')),
              iconSize: 30.0,
              onPressed: () => _temperatureUp(entity, 0.5),
            ),
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName('mdi:chevron-double-down')),
              iconSize: 30.0,
              onPressed: () => _temperatureDown(entity, 0.5),
            )
          ],
        )
      ]);
    } else if (entity.supportTargetTemperatureHigh && entity.supportTargetTemperatureLow) {
      result.addAll(<Widget>[
        Text(
          "$_tmpTargetLow",
          style: TextStyle(
              fontSize: entity.largeFontSize,
              color: _showPending ? Colors.red : Colors.black
          ),
        ),
        Column(
          children: <Widget>[
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName('mdi:chevron-up')),
              iconSize: 30.0,
              onPressed: () => _targetLowUp(entity, 0.1),
            ),
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName('mdi:chevron-down')),
              iconSize: 30.0,
              onPressed: () => _targetLowDown(entity, 0.1),
            )
          ],
        ),
        Column(
          children: <Widget>[
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName('mdi:chevron-double-up')),
              iconSize: 30.0,
              onPressed: () => _targetLowUp(entity, 0.5),
            ),
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName('mdi:chevron-double-down')),
              iconSize: 30.0,
              onPressed: () => _targetLowDown(entity, 0.5),
            )
          ],
        ),
        Expanded(
          child: Container(height: 10.0),
        ),
        Text(
          "$_tmpTargetHigh",
          style: TextStyle(
              fontSize: entity.largeFontSize,
              color: _showPending ? Colors.red : Colors.black
          ),
        ),
        Column(
          children: <Widget>[
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName('mdi:chevron-up')),
              iconSize: 30.0,
              onPressed: () => _targetHighUp(entity, 0.1),
            ),
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName('mdi:chevron-down')),
              iconSize: 30.0,
              onPressed: () => _targetHighDown(entity, 0.1),
            )
          ],
        ),
        Column(
          children: <Widget>[
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName('mdi:chevron-double-up')),
              iconSize: 30.0,
              onPressed: () => _targetHighUp(entity, 0.5),
            ),
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName('mdi:chevron-double-down')),
              iconSize: 30.0,
              onPressed: () => _targetHighDown(entity, 0.5),
            )
          ],
        )
      ]);
    } else if (entity.supportTargetTemperatureHigh || entity.supportTargetTemperatureLow) {
      result.add(Text("Unsupported temperature control. Please, report an issue."));
    }
    if (result.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Target temperature", style: TextStyle(
              fontSize: entity.stateFontSize
          )),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: result,
          )
        ],
      );
    } else {
      return Container(height: 0.0, width: 0.0,);
    }
  }

  Widget _buildHumidityControls(ClimateEntity entity) {
    List<Widget> result = [];
    if (entity.supportTargetHumidity) {
      result.addAll(<Widget>[
        Text(
          "$_tmpTargetHumidity%",
          style: TextStyle(fontSize: entity.largeFontSize),
        ),
        Expanded(
          child: Slider(
            value: _tmpTargetHumidity,
            max: entity.maxHumidity,
            min: entity.minHumidity,
            onChanged: ((double val) {
              setState(() {
                _changedHere = true;
                _tmpTargetHumidity = val.roundToDouble();
              });
            }),
            onChangeEnd: (double v) => _setTargetHumidity(entity, v),
          ),
        )
      ]);
    }
    if (result.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
                0.0, entity.rowPadding, 0.0, entity.rowPadding),
            child: Text("Target humidity", style: TextStyle(
                fontSize: entity.stateFontSize
            )),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: result,
          ),
          Container(
            height: entity.rowPadding,
          )
        ],
      );
    } else {
      return Container(
        width: 0.0,
        height: 0.0,
      );
    }
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

class CoverControlWidget extends StatefulWidget {

  CoverControlWidget({Key key}) : super(key: key);

  @override
  _CoverControlWidgetState createState() => _CoverControlWidgetState();
}

class _CoverControlWidgetState extends State<CoverControlWidget> {

  double _tmpPosition = 0.0;
  double _tmpTiltPosition = 0.0;
  bool _changedHere = false;

  void _setNewPosition(CoverEntity entity, double position) {
    setState(() {
      _tmpPosition = position.roundToDouble();
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_cover_position", entity.entityId,{"position": _tmpPosition.round()}));
    });
  }

  void _setNewTiltPosition(CoverEntity entity, double position) {
    setState(() {
      _tmpTiltPosition = position.roundToDouble();
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(entity.domain, "set_cover_tilt_position", entity.entityId,{"tilt_position": _tmpTiltPosition.round()}));
    });
  }

  void _resetVars(CoverEntity entity) {
    _tmpPosition = entity.currentPosition;
    _tmpTiltPosition = entity.currentTiltPosition;
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final CoverEntity entity = entityModel.entity;
    if (_changedHere) {
      _changedHere = false;
    } else {
      _resetVars(entity);
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(entity.leftWidgetPadding, entity.rowPadding, entity.rightWidgetPadding, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildPositionControls(entity),
          _buildTiltControls(entity)
        ],
      ),
    );
  }

  Widget _buildPositionControls(CoverEntity entity) {
    if (entity.supportSetPosition) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(
                0.0, entity.rowPadding, 0.0, entity.rowPadding),
            child: Text("Position", style: TextStyle(
                fontSize: entity.stateFontSize
            )),
          ),
          Slider(
            value: _tmpPosition,
            min: 0.0,
            max: 100.0,
            divisions: 10,
            onChanged: (double value) {
              setState(() {
                _tmpPosition = value.roundToDouble();
                _changedHere = true;
              });
            },
            onChangeEnd: (double value) => _setNewPosition(entity, value),
          ),
          Container(height: entity.rowPadding,)
        ],
      );
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildTiltControls(CoverEntity entity) {
    List<Widget> controls = [];
    if (entity.supportCloseTilt || entity.supportOpenTilt || entity.supportStopTilt) {
      controls.add(
        CoverEntityTiltControlState()
      );
    }
    if (entity.supportSetTiltPosition) {
      controls.addAll(<Widget>[
        Slider(
          value: _tmpTiltPosition,
          min: 0.0,
          max: 100.0,
          divisions: 10,
          onChanged: (double value) {
            setState(() {
              _tmpTiltPosition = value.roundToDouble();
              _changedHere = true;
            });
          },
          onChangeEnd: (double value) => _setNewTiltPosition(entity, value),
        ),
        Container(height: entity.rowPadding,)
      ]);
    }
    if (controls.isNotEmpty) {
      controls.insert(0, Padding(
        padding: EdgeInsets.fromLTRB(
            0.0, entity.rowPadding, 0.0, entity.rowPadding),
        child: Text("Tilt position", style: TextStyle(
            fontSize: entity.stateFontSize
        )),
      ));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: controls,
      );
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

}