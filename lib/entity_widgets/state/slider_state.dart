part of '../../main.dart';

class SliderStateWidget extends StatefulWidget {

  final bool expanded;

  SliderStateWidget({Key key, @required this.expanded}) : super(key: key);

  @override
  _SliderStateWidgetState createState() => _SliderStateWidgetState();
}

class _SliderStateWidgetState extends State<SliderStateWidget> {
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