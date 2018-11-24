part of '../main.dart';

class FanEntity extends Entity {

  static const SUPPORT_SET_SPEED = 1;
  static const SUPPORT_OSCILLATE = 2;
  static const SUPPORT_DIRECTION = 4;

  FanEntity(Map rawData) : super(rawData);

  bool get supportSetSpeed => ((attributes["supported_features"] &
  FanEntity.SUPPORT_SET_SPEED) ==
      FanEntity.SUPPORT_SET_SPEED);
  bool get supportOscillate => ((attributes["supported_features"] &
  FanEntity.SUPPORT_OSCILLATE) ==
      FanEntity.SUPPORT_OSCILLATE);
  bool get supportDirection => ((attributes["supported_features"] &
  FanEntity.SUPPORT_DIRECTION) ==
      FanEntity.SUPPORT_DIRECTION);

  List<String> get speedList => getStringListAttributeValue("speed_list");

  @override
  Widget _buildStatePart(BuildContext context) {
    return SwitchStateWidget();
  }

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return FanControlsWidget();
  }
}