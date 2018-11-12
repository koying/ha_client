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
    Widget result;
    if (entity.state == "unavailable") {
      return SimpleEntityState();
    } else if ((entity.attributes["assumed_state"] == null) || (entity.attributes["assumed_state"] == false)) {
      return SizedBox(
        height: 32.0,
        child: Switch(
          value: entity.assumedState == 'on',
          onChanged: ((switchState) {
            _setNewState(switchState, entity);
          }),
        )
      );
    } else {
      return SizedBox(
        height: 32.0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            IconButton(
              onPressed: () => _setNewState(false, entity),
              icon: Icon(MaterialDesignIcons.createIconDataFromIconName("mdi:flash-off")),
              color: entity.assumedState == 'on' ? Colors.black : Colors.blue,
              iconSize: Sizes.iconSize,
            ),
            IconButton(
                onPressed: () => _setNewState(true, entity),
                icon: Icon(MaterialDesignIcons.createIconDataFromIconName("mdi:flash")),
                color: entity.assumedState == 'on' ? Colors.blue : Colors.black,
                iconSize: Sizes.iconSize
            )
          ],
        ),
      );
    }
  }
}