part of '../main.dart';

class LightEntity extends Entity {

  static const SUPPORT_BRIGHTNESS = 1;
  static const SUPPORT_COLOR_TEMP = 2;
  static const SUPPORT_EFFECT = 4;
  static const SUPPORT_FLASH = 8;
  static const SUPPORT_COLOR = 16;
  static const SUPPORT_TRANSITION = 32;
  static const SUPPORT_WHITE_VALUE = 128;

  bool get supportBrightness => ((attributes["supported_features"] &
  LightEntity.SUPPORT_BRIGHTNESS) ==
      LightEntity.SUPPORT_BRIGHTNESS);
  bool get supportColorTemp => ((attributes["supported_features"] &
  LightEntity.SUPPORT_COLOR_TEMP) ==
      LightEntity.SUPPORT_COLOR_TEMP);
  bool get supportEffect => ((attributes["supported_features"] &
  LightEntity.SUPPORT_EFFECT) ==
      LightEntity.SUPPORT_EFFECT);
  bool get supportFlash => ((attributes["supported_features"] &
  LightEntity.SUPPORT_FLASH) ==
      LightEntity.SUPPORT_FLASH);
  bool get supportColor => ((attributes["supported_features"] &
  LightEntity.SUPPORT_COLOR) ==
      LightEntity.SUPPORT_COLOR);
  bool get supportTransition => ((attributes["supported_features"] &
  LightEntity.SUPPORT_TRANSITION) ==
      LightEntity.SUPPORT_TRANSITION);
  bool get supportWhiteValue => ((attributes["supported_features"] &
  LightEntity.SUPPORT_WHITE_VALUE) ==
      LightEntity.SUPPORT_WHITE_VALUE);

  int get brightness => _getIntAttributeValue("brightness");
  String get effect => attributes["effect"];
  int get colorTemp => _getIntAttributeValue("color_temp");
  double get maxMireds => _getDoubleAttributeValue("max_mireds");
  double get minMireds => _getDoubleAttributeValue("min_mireds");
  Color get color => _getColor();
  bool get isAdditionalControls => ((attributes["supported_features"] != null) && (attributes["supported_features"] != 0));
  List<String> get effectList => getStringListAttributeValue("effect_list");

  LightEntity(Map rawData) : super(rawData);

  Color _getColor() {
    List rgb = attributes["rgb_color"];
    try {
      if ((rgb != null) && (rgb.length > 0)) {
        return Color.fromARGB(255, rgb[0], rgb[1], rgb[2]);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  @override
  Widget _buildStatePart(BuildContext context) {
    return SwitchStateWidget();
  }

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    if (!isAdditionalControls) {
      return Container(height: 0.0, width: 0.0);
    } else {
      return LightControlsWidget();
    }
  }

}