part of '../main.dart';

class _ClimateEntityWidgetState extends _EntityWidgetState {

  List<String> _operationList = [];
  double _temperature1 = 0.0;
  String _operationMode = "";
  bool _awayMode = false;
  bool _showPending;
  bool _changedHere;
  double _temperatureStep = 0.2;
  Timer _resetTimer;

  @override
  double widgetHeight = 38.0;

  @override
  void initState() {
    _operationList.clear();
    if (widget.entity.attributes["operation_list"] != null) {
      widget.entity.attributes["operation_list"].forEach((value){
        _operationList.add(value.toString());
      });
    }
    _resetVars();
    super.initState();
  }

  void _resetVars() {
    var temp1 = widget.entity.attributes['temperature'] ?? widget.entity.attributes['target_temp_low'];
    if (temp1 is int) {
      _temperature1 = temp1.toDouble();
    } else if (temp1 is double) {
      _temperature1 = temp1;
    }
    _operationMode = widget.entity.attributes['operation_mode'];
    _awayMode = widget.entity.attributes['away_mode'] == "on";
    _showPending = false;
    _changedHere = false;
  }

  @override
  Widget _buildSecondRowWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        super._buildSecondRowWidget(),
        _buildAdditionalControls()
      ],
    );
  }

  void _temperatureUp() {
    _temperature1 += _temperatureStep;
    _setTemperature();
  }

  void _temperatureDown() {
    _temperature1 -= _temperatureStep;
    _setTemperature();
  }

  void _setTemperature() {
    setState(() {
      _temperature1 = double.parse(_temperature1.toStringAsFixed(1));
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(widget.entity.domain, "set_temperature", widget.entity.entityId,{"temperature": "${_temperature1.toStringAsFixed(1)}"}));
      _resetStateTimer();
    });
  }

  void _setOperationMode(value) {
    setState(() {
      _operationMode = value;
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(widget.entity.domain, "set_operation_mode", widget.entity.entityId,{"operation_mode": "$_operationMode"}));
      _resetStateTimer();
    });
  }

  void _setAwayMode(value) {
    setState(() {
      _awayMode = value;
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(widget.entity.domain, "set_away_mode", widget.entity.entityId,{"away_mode": "${_awayMode ? 'on' : 'off'}"}));
      _resetStateTimer();
    });
  }

  void _resetStateTimer() {
    if (_resetTimer!=null) {
      _resetTimer.cancel();
    }
    _resetTimer = Timer(Duration(seconds: 3), () {
    setState(() {});
      _resetVars();
    });
  }

  _buildAdditionalControls() {
    if (_changedHere) {
      _showPending = (_temperature1 != widget.entity.attributes['temperature']);
      _changedHere = false;
    } else {
      _resetTimer?.cancel();
      _resetVars();
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(leftWidgetPadding, rowPadding, rightWidgetPadding, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Target temperature for ${_operationMode != 'off' ? _operationMode : ''}", style: TextStyle(
              fontSize: stateFontSize
          )),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  "$_temperature1",
                  style: TextStyle(
                    fontSize: largeFontSize,
                    color: _showPending ? Colors.red : Colors.black
                  ),
                ),
              ),
              Column(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_up),
                    iconSize: 30.0,
                    onPressed: () => _temperatureUp(),
                  ),
                  IconButton(
                    icon: Icon(Icons.keyboard_arrow_down),
                    iconSize: 30.0,
                    onPressed: () => _temperatureDown(),
                  )
                ],
              )
            ],
          ),
          Text("Operation", style: TextStyle(
              fontSize: stateFontSize
          )),
          DropdownButton<String>(
            value: "$_operationMode",
            iconSize: 30.0,
            style: TextStyle(
              fontSize: largeFontSize,
              color: Colors.black,
            ),
            items: this._operationList.map((String value) {
              return new DropdownMenuItem<String>(
                value: value,
                child: new Text(value),
              );
            }).toList(),
            onChanged: (_) => _setOperationMode(_),
          ),
          Padding(
            padding: EdgeInsets.only(top: rowPadding),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    "Away mode",
                    style: TextStyle(
                      fontSize: stateFontSize
                    ),
                  ),
                ),
                Switch(
                  onChanged: (value) => _setAwayMode(value),
                  value: _awayMode,
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget _buildActionWidget(BuildContext context) {
    return Padding(
        padding:
        EdgeInsets.fromLTRB(0.0, 0.0, rightWidgetPadding, 0.0),
        child: GestureDetector(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                      "${widget.entity.state}",
                      textAlign: TextAlign.right,
                      style: new TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: stateFontSize,
                      )),
                  Text(
                      " ${widget.entity.attributes["temperature"]}",
                      textAlign: TextAlign.right,
                      style: new TextStyle(
                        fontSize: stateFontSize,
                      ))
                ],
              ),
              Text(
                  "Currently: ${widget.entity.attributes["current_temperature"]}",
                  textAlign: TextAlign.right,
                  style: new TextStyle(
                    fontSize: stateFontSize,
                    color: Colors.black45
                  ))
            ],
          ),
          onTap: openEntityPage,
        )
    );
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

}