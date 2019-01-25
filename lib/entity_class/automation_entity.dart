part of '../main.dart';

class AutomationEntity extends Entity {
  AutomationEntity(Map rawData) : super(rawData);

  @override
  Widget _buildStatePart(BuildContext context) {
    return SwitchStateWidget();
  }

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        FlatServiceButton(
          text: "TRIGGER",
          serviceName: "trigger",
        )
      ],
    );
  }
}