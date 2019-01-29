part of '../main.dart';

class AlarmControlPanelEntity extends Entity {
  AlarmControlPanelEntity(Map rawData) : super(rawData);

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return AlarmControlPanelControlsWidget(
      extended: false,
    );
  }
}