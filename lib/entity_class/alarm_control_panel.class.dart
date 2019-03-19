part of '../main.dart';

class AlarmControlPanelEntity extends Entity {
  AlarmControlPanelEntity(Map rawData, String webHost) : super(rawData, webHost);


  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return AlarmControlPanelControlsWidget(
      extended: false,
    );
  }
}