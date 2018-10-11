part of '../main.dart';

class _SliderEntityWidgetState extends _EntityWidgetState {
  int _multiplier = 1;

  double get minValue => widget.entity.attributes["min"] ?? 0.0;
  double get maxValue => widget.entity.attributes["max"] ?? 100.0;
  double get valueStep => widget.entity.attributes["step"] ?? 1.0;
  double get doubleState => double.tryParse(widget.entity.state) ?? 0.0;

  @override
  void initState() {
    super.initState();
    if (valueStep < 1) {
      _multiplier = 10;
    } else if (valueStep < 0.1) {
      _multiplier = 100;
    }
  }

  @override
  void setNewState(newValue) {
    eventBus.fire(new ServiceCallEvent(widget.entity.domain, "set_value", widget.entity.entityId,
        {"value": "${newValue.toString()}"}));
  }

  @override
  Widget _buildSecondRowWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        super._buildSecondRowWidget(),
        _buildExtendedSlider()
      ],
    );
  }

  Widget _buildExtendedSlider() {
    return Slider(
      min: this.minValue * _multiplier,
      max: this.maxValue * _multiplier,
      value: (doubleState <= this.maxValue) &&
          (doubleState >= this.minValue)
          ? doubleState * _multiplier
          : this.minValue * _multiplier,
      onChanged: (value) {
        setState(() {
          widget.entity.state =
              (value.roundToDouble() / _multiplier).toString();
        });
        /*eventBus.fire(new StateChangedEvent(widget.entity.entityId,
                      (value.roundToDouble() / _multiplier).toString(), true));*/
      },
      onChangeEnd: (value) {
        setNewState(value.roundToDouble() / _multiplier);
      },
    );
  }

  @override
  Widget _buildActionWidget(BuildContext context) {
    Widget stateWidget = Padding(
      padding: EdgeInsets.only(right: rightWidgetPadding),
      child: Text("${widget.entity.state}${widget.entity.unitOfMeasurement}",
          textAlign: TextAlign.right,
          style: new TextStyle(
            fontSize: stateFontSize,
          )),
    );
    if (widget.widgetType == EntityWidgetType.regular) {
      return Expanded(
        //width: 200.0,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Slider(
                min: this.minValue * _multiplier,
                max: this.maxValue * _multiplier,
                value: (doubleState <= this.maxValue) &&
                    (doubleState >= this.minValue)
                    ? doubleState * _multiplier
                    : this.minValue * _multiplier,
                onChanged: (value) {
                  setState(() {
                    widget.entity.state =
                        (value.roundToDouble() / _multiplier).toString();
                  });
                  /*eventBus.fire(new StateChangedEvent(widget.entity.entityId,
                      (value.roundToDouble() / _multiplier).toString(), true));*/
                },
                onChangeEnd: (value) {
                  setNewState(value.roundToDouble() / _multiplier);
                },
              ),
            ),
            stateWidget
          ],
        ),
      );
    } else {
      return stateWidget;
    }
  }
}