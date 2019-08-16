part of '../../main.dart';

class ClimateStateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final ClimateEntity entity = entityModel.entityWrapper.entity;
    String targetTemp = "-";
    if ((entity.supportTargetTemperature) && (entity.temperature != null)) {
      targetTemp = "${entity.temperature}";
    } else if ((entity.supportTargetTemperatureRange) &&
        (entity.targetLow != null) &&
        (entity.targetHigh != null)) {
      targetTemp = "${entity.targetLow} - ${entity.targetHigh}";
    }
    String displayState = '';
    if (entity.hvacAction != null) {
      displayState = "${entity.hvacAction} (${entity.displayState})";
    } else {
      displayState = "${entity.displayState}";
    }
    if (entity.presetMode != null) {
      displayState += " - ${entity.presetMode}";
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
                Text("$displayState",
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
            entity.currentTemperature != null ?
            Text("Currently: ${entity.currentTemperature}",
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