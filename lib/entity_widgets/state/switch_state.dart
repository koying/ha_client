part of '../../main.dart';

class SwitchStateWidget extends StatefulWidget {
  @override
  _SwitchStateWidgetState createState() => _SwitchStateWidgetState();
}

class _SwitchStateWidgetState extends State<SwitchStateWidget> {

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
    final entity = entityModel.entity;
    if ((entity.attributes["assumed_state"] == null) || (entity.attributes["assumed_state"] == false)) {
      return Switch(
        value: entity.assumedState == 'on',
        onChanged: ((switchState) {
          _setNewState(switchState, entity);
        }),
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          IconButton(
            onPressed: () => _setNewState(false, entity),
            icon: Icon(MaterialDesignIcons.createIconDataFromIconName("mdi:flash-off")),
            color: entity.assumedState == 'on' ? Colors.black : Colors.blue,
            iconSize: Entity.iconSize,
          ),
          IconButton(
              onPressed: () => _setNewState(true, entity),
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName("mdi:flash")),
              color: entity.assumedState == 'on' ? Colors.blue : Colors.black,
              iconSize: Entity.iconSize
          )
        ],
      );
    }

  }
}