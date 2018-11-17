part of '../../main.dart';

class LightControlsWidget extends StatefulWidget {

  @override
  _LightControlsWidgetState createState() => _LightControlsWidgetState();

}

class _LightControlsWidgetState extends State<LightControlsWidget> {

  int _tmpBrightness;
  int _tmpColorTemp;
  Color _tmpColor;
  bool _changedHere = false;
  String _tmpEffect;

  void _resetState(LightEntity entity) {
    _tmpBrightness = entity.brightness ?? 0;
    _tmpColorTemp = entity.colorTemp;
    _tmpColor = entity.color;
    _tmpEffect = null;
  }

  void _setBrightness(LightEntity entity, double value) {
    setState(() {
      _tmpBrightness = value.round();
      _changedHere = true;
      if (_tmpBrightness > 0) {
        eventBus.fire(new ServiceCallEvent(
            entity.domain, "turn_on", entity.entityId,
            {"brightness": _tmpBrightness}));
      } else {
        eventBus.fire(new ServiceCallEvent(
            entity.domain, "turn_off", entity.entityId,
            null));
      }
    });
  }

  void _setColorTemp(LightEntity entity, double value) {
    setState(() {
      _tmpColorTemp = value.round();
      _changedHere = true;
      eventBus.fire(new ServiceCallEvent(
          entity.domain, "turn_on", entity.entityId,
          {"color_temp": _tmpColorTemp}));
    });
  }

  void _setColor(LightEntity entity, Color color) {
    setState(() {
      _tmpColor = color;
      _changedHere = true;
      TheLogger.debug( "Color: [${color.red}, ${color.green}, ${color.blue}]");
      if ((color == Colors.black) || ((color.red == color.green) && (color.green == color.blue)))  {
        eventBus.fire(new ServiceCallEvent(
            entity.domain, "turn_off", entity.entityId,
            null));
      } else {
        eventBus.fire(new ServiceCallEvent(
            entity.domain, "turn_on", entity.entityId,
            {"rgb_color": [color.red, color.green, color.blue]}));
      }
    });
  }

  void _setEffect(LightEntity entity, String value) {
    setState(() {
      _tmpEffect = value;
      _changedHere = true;
      if (_tmpEffect != null) {
        eventBus.fire(new ServiceCallEvent(
            entity.domain, "turn_on", entity.entityId,
            {"effect": "$value"}));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final LightEntity entity = entityModel.entityWrapper.entity;
    if (!_changedHere) {
      _resetState(entity);
    } else {
      _changedHere = false;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _buildBrightnessControl(entity),
        _buildColorTempControl(entity),
        _buildColorControl(entity),
        _buildEffectControl(entity)
      ],
    );
  }

  Widget _buildBrightnessControl(LightEntity entity) {
    if ((entity.supportBrightness) && (_tmpBrightness != null) && (entity.state != EntityState.unavailable)) {
      return UniversalSlider(
        onChanged: (value) {
          setState(() {
            _changedHere = true;
            _tmpBrightness = value.round();
          });
        },
        min: 0.0,
        max: 255.0,
        onChangeEnd: (value) => _setBrightness(entity, value),
        value: _tmpBrightness.toDouble(),
        leading: Icon(Icons.brightness_5),
        title: "Brightness",
      );
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildColorTempControl(LightEntity entity) {
    if ((entity.supportColorTemp) && (_tmpColorTemp != null)) {
      return UniversalSlider(
        title: "Color temperature",
        leading: Text("Cold", style: TextStyle(color: Colors.lightBlue),),
        value:  _tmpColorTemp.toDouble(),
        onChangeEnd: (value) => _setColorTemp(entity, value),
        max: entity.maxMireds,
        min: entity.minMireds,
        onChanged: (value) {
          setState(() {
            _changedHere = true;
            _tmpColorTemp = value.round();
          });
        },
        closing: Text("Warm", style: TextStyle(color: Colors.amberAccent),),
      );
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildColorControl(LightEntity entity) {
    if ((entity.supportColor) && (entity.color != null)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(height: Sizes.rowPadding,),
          RaisedButton(
            onPressed: () => _showColorPicker(entity),
            color: _tmpColor ?? Colors.black45,
            child: Text(
              "COLOR",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 50.0,
                fontWeight: FontWeight.bold,
                color: Colors.black12,
              ),
            ),
          ),
          Container(height: 2*Sizes.rowPadding,),
        ],
      );
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }

  void _showColorPicker(LightEntity entity) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: EdgeInsets.all(0.0),
          contentPadding: EdgeInsets.all(0.0),
          content: SingleChildScrollView(
            child: MaterialPicker(
              pickerColor: _tmpColor,
              onColorChanged: (color) {
                _setColor(entity, color);
                Navigator.of(context).pop();
              },
              enableLabel: true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEffectControl(LightEntity entity) {
    if ((entity.supportEffect) && (entity.effectList != null)) {
      return ModeSelectorWidget(
          onChange: (effect) => _setEffect(entity, effect),
          caption: "Effect",
          options: entity.effectList,
          value: _tmpEffect
      );
    } else {
      return Container(width: 0.0, height: 0.0);
    }
  }


}