part of '../../main.dart';

class SelectStateWidget extends StatefulWidget {

  SelectStateWidget({Key key}) : super(key: key);

  @override
  _SelectStateWidgetState createState() => _SelectStateWidgetState();
}

class _SelectStateWidgetState extends State<SelectStateWidget> {

  void setNewState(domain, entityId, newValue) {
    eventBus.fire(new ServiceCallEvent(domain, "select_option", entityId,
        {"option": "$newValue"}));
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final SelectEntity entity = entityModel.entity.entity;
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