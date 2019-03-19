part of '../main.dart';

class FanEntity extends Entity {

  static const SUPPORT_SET_SPEED = 1;
  static const SUPPORT_OSCILLATE = 2;
  static const SUPPORT_DIRECTION = 4;

  FanEntity(Map rawData, String webHost) : super(rawData, webHost);

  bool get supportSetSpeed => ((supportedFeatures &
  FanEntity.SUPPORT_SET_SPEED) ==
      FanEntity.SUPPORT_SET_SPEED);
  bool get supportOscillate => ((supportedFeatures &
  FanEntity.SUPPORT_OSCILLATE) ==
      FanEntity.SUPPORT_OSCILLATE);
  bool get supportDirection => ((supportedFeatures &
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