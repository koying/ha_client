part of '../../main.dart';

class ClimateStateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final ClimateEntity entity = entityModel.entityWrapper.entity;
    String targetTemp = "-";
    if ((entity.supportTargetTemperature) && (entity.temperature != null)) {
      targetTemp = "${entity.temperature}";
    } else if ((entity.supportTargetTemperatureLow) &&
        (entity.targetLow != null)) {
      targetTemp = "${entity.targetLow}";
      if ((entity.supportTargetTemperatureHigh) &&
          (entity.targetHigh != null)) {
        targetTemp += " - ${entity.targetHigh}";
      }
    }
    return Padding(
        padding: EdgeInsets.fromLTRB(
            0.0, 0.0, Sizes.rightWidgetPadding, 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Text("${entity.state}",
                    textAlign: TextAlign.right,
                    style: new TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: Sizes.stateFontSize,
                    )),
                Text(" $targetTemp",
                    textAlign: TextAlign.right,
                    style: new TextStyle(
                      fontSize: Sizes.stateFontSize,
                    ))
              ],
            ),
            entity.attributes["current_temperature"] != null ?
            Text("Currently: ${entity.attributes["current_temperature"]}",
                textAlign: TextAlign.right,
                style: new TextStyle(
                    fontSize: Sizes.stateFontSize,
                    color: Colors.black45)
            ) :
            Container(height: 0.0,)
          ],
        ));
  }
}