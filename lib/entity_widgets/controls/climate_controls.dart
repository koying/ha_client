part of '../../main.dart';

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
      padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, Sizes.rowPadding, Sizes.rightWidgetPadding, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildOnOffControl(entity),
          _buildTemperatureControls(entity),
          _buildTargetTemperatureControls(entity),
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
      return ModeSwitchWidget(
        caption: "Away mode",
        onChange: (value) => _setAwayMode(entity, value),
        value: _tmpAwayMode,
      );
    } else {
      return Container(height: 0.0, width: 0.0,);
    }
  }

  Widget _buildOnOffControl(ClimateEntity entity) {
    if (entity.supportOnOff) {
      return ModeSwitchWidget(
          onChange: (value) => _setOnOf(entity, value),
          caption: "On / Off",
          value: !_tmpIsOff
      );
    } else {
      return Container(height: 0.0, width: 0.0,);
    }
  }

  Widget _buildAuxHeatControl(ClimateEntity entity) {
    if (entity.supportAuxHeat ) {
      return ModeSwitchWidget(
          caption: "Aux heat",
          onChange: (value) => _setAuxHeat(entity, value),
          value: _tmpAuxHeat
      );
    } else {
      return Container(height: 0.0, width: 0.0,);
    }
  }

  Widget _buildOperationControl(ClimateEntity entity) {
    if (entity.supportOperationMode) {
      return ModeSelectorWidget(
        onChange: (mode) => _setOperationMode(entity, mode),
        options: entity.operationList,
        caption: "Operation",
        value: _tmpOperationMode,
      );
    } else {
      return Container(height: 0.0, width: 0.0);
    }
  }

  Widget _buildFanControl(ClimateEntity entity) {
    if (entity.supportFanMode) {
      return ModeSelectorWidget(
        options: entity.fanList,
        onChange: (mode) => _setFanMode(entity, mode),
        caption: "Fan mode",
        value: _tmpFanMode,
      );
    } else {
      return Container(height: 0.0, width: 0.0);
    }
  }

  Widget _buildSwingControl(ClimateEntity entity) {
    if (entity.supportSwingMode) {
      return ModeSelectorWidget(
          onChange: (mode) => _setSwingMode(entity, mode),
          options: entity.swingList,
          value: _tmpSwingMode,
          caption: "Swing mode"
      );
    } else {
      return Container(height: 0.0, width: 0.0);
    }
  }

  Widget _buildTemperatureControls(ClimateEntity entity) {
    if ((entity.supportTargetTemperature) && (entity.temperature != null)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Target temperature", style: TextStyle(
              fontSize: Sizes.stateFontSize
          )),
          TemperatureControlWidget(
            value: _tmpTemperature,
            fontColor: _showPending ? Colors.red : Colors.black,
            onLargeDec: () => _temperatureDown(entity, 0.5),
            onLargeInc: () => _temperatureUp(entity, 0.5),
            onSmallDec: () => _temperatureDown(entity, 0.1),
            onSmallInc: () => _temperatureUp(entity, 0.1),
          )
        ],
      );
    } else {
      return Container(width: 0.0, height: 0.0,);
    }
  }

  Widget _buildTargetTemperatureControls(ClimateEntity entity) {
    List<Widget> controls = [];
    if ((entity.supportTargetTemperatureLow) && (entity.targetLow != null)) {
      controls.addAll(<Widget>[
        TemperatureControlWidget(
          value: _tmpTargetLow,
          fontColor: _showPending ? Colors.red : Colors.black,
          onLargeDec: () => _targetLowDown(entity, 0.5),
          onLargeInc: () => _targetLowUp(entity, 0.5),
          onSmallDec: () => _targetLowDown(entity, 0.1),
          onSmallInc: () => _targetLowUp(entity, 0.1),
        ),
        Expanded(
          child: Container(height: 10.0),
        )
      ]);
    }
    if ((entity.supportTargetTemperatureHigh) && (entity.targetHigh != null)) {
      controls.add(
          TemperatureControlWidget(
            value: _tmpTargetHigh,
            fontColor: _showPending ? Colors.red : Colors.black,
            onLargeDec: () => _targetHighDown(entity, 0.5),
            onLargeInc: () => _targetHighUp(entity, 0.5),
            onSmallDec: () => _targetHighDown(entity, 0.1),
            onSmallInc: () => _targetHighUp(entity, 0.1),
          )
      );
    }
    if (controls.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Target temperature range", style: TextStyle(
              fontSize: Sizes.stateFontSize
          )),
          Row(
            children: controls,
          )
        ],
      );
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildHumidityControls(ClimateEntity entity) {
    List<Widget> result = [];
    if (entity.supportTargetHumidity) {
      result.addAll(<Widget>[
        Text(
          "$_tmpTargetHumidity%",
          style: TextStyle(fontSize: Sizes.largeFontSize),
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
                0.0, Sizes.rowPadding, 0.0, Sizes.rowPadding),
            child: Text("Target humidity", style: TextStyle(
                fontSize: Sizes.stateFontSize
            )),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: result,
          ),
          Container(
            height: Sizes.rowPadding,
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

class TemperatureControlWidget extends StatelessWidget {
  final double value;
  final double fontSize;
  final Color fontColor;
  final onSmallInc;
  final onLargeInc;
  final onSmallDec;
  final onLargeDec;

  TemperatureControlWidget(
      {Key key,
        @required this.value,
        @required this.onSmallInc,
        @required this.onSmallDec,
        @required this.onLargeInc,
        @required this.onLargeDec,
        this.fontSize,
        this.fontColor})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          "$value",
          style: TextStyle(
              fontSize: fontSize ?? 24.0,
              color: fontColor ?? Colors.black
          ),
        ),
        Column(
          children: <Widget>[
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName(
                  'mdi:chevron-up')),
              iconSize: 30.0,
              onPressed: () => onSmallInc(),
            ),
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName(
                  'mdi:chevron-down')),
              iconSize: 30.0,
              onPressed: () => onSmallDec(),
            )
          ],
        ),
        Column(
          children: <Widget>[
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName(
                  'mdi:chevron-double-up')),
              iconSize: 30.0,
              onPressed: () => onLargeInc(),
            ),
            IconButton(
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName(
                  'mdi:chevron-double-down')),
              iconSize: 30.0,
              onPressed: () => onLargeDec(),
            )
          ],
        )
      ],
    );
  }
}