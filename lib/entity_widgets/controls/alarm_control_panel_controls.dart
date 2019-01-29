part of '../../main.dart';

class AlarmControlPanelControlsWidget extends StatefulWidget {

  @override
  _AlarmControlPanelControlsWidgetWidgetState createState() => _AlarmControlPanelControlsWidgetWidgetState();

}

class _AlarmControlPanelControlsWidgetWidgetState extends State<AlarmControlPanelControlsWidget> {

  String code = "";

  void _callService(AlarmControlPanelEntity entity, String service) {
    eventBus.fire(new ServiceCallEvent(
          entity.domain, service, entity.entityId,
          {"code": "$code"}));
    setState(() {
      code = "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final AlarmControlPanelEntity entity = entityModel.entityWrapper.entity;
    List<Widget> buttons = [];
    if (entity.state == EntityState.alarm_disarmed) {
      buttons.addAll(<Widget>[
          RaisedButton(
            onPressed: () => _callService(entity, "alarm_arm_home"),
            child: Text("ARM HOME"),
          ),
          RaisedButton(
            onPressed: () => _callService(entity, "alarm_arm_away"),
            child: Text("ARM AWAY"),
          )
        ]
      );
    } else {
      buttons.add(
        RaisedButton(
          onPressed: () => _callService(entity, "alarm_disarm"),
          child: Text("DISARM"),
        )
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: <Widget>[
        Container(
          width: 150.0,
          child: TextField(
            //focusNode: _focusNode,
              obscureText: true,
              controller: new TextEditingController.fromValue(
                  new TextEditingValue(
                      text: code,
                      selection:
                      new TextSelection.collapsed(offset: code.length)
                  )
              ),
              onChanged: (value) {
                code = value;
              }
          )
        ),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10.0,
          runSpacing: 1.0,
          children: buttons
        )
      ]

    );
  }


}