part of '../../main.dart';

class AlarmControlPanelControlsWidget extends StatefulWidget {

  @override
  _AlarmControlPanelControlsWidgetWidgetState createState() => _AlarmControlPanelControlsWidgetWidgetState();

}

class _AlarmControlPanelControlsWidgetWidgetState extends State<AlarmControlPanelControlsWidget> {

  void _disarm(AlarmControlPanelEntity entity, String code) {
    eventBus.fire(new ServiceCallEvent(
          entity.domain, "alarm_disarm", entity.entityId,
          {"code": "$code"}));
  }

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final AlarmControlPanelEntity entity = entityModel.entityWrapper.entity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,

      children: <Widget>[
        TextField(
            //focusNode: _focusNode,
            obscureText: true,
            /*controller: new TextEditingController.fromValue(
                new TextEditingValue(
                    text: _tmpValue,
                    selection:
                    new TextSelection.collapsed(offset: _tmpValue.length)
                )
            ),*/
            onChanged: (value) {
              Logger.d('Alarm code: $value');
            })
      ],
    );
  }


}