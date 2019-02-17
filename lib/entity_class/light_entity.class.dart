part of '../main.dart';

class LightEntity extends Entity {

  static const SUPPORT_BRIGHTNESS = 1;
  static const SUPPORT_COLOR_TEMP = 2;
  static const SUPPORT_EFFECT = 4;
  static const SUPPORT_FLASH = 8;
  static const SUPPORT_COLOR = 16;
  static const SUPPORT_TRANSITION = 32;
  static const SUPPORT_WHITE_VALUE = 128;

  bool get supportBrightness => ((supportedFeatures &
  LightEntity.SUPPORT_BRIGHTNESS) ==
      LightEntity.SUPPORT_BRIGHTNESS);
  bool get supportColorTemp => ((supportedFeatures &
  LightEntity.SUPPORT_COLOR_TEMP) ==
      LightEntity.SUPPORT_COLOR_TEMP);
  bool get supportEffect => ((supportedFeatures &
  LightEntity.SUPPORT_EFFECT) ==
      LightEntity.SUPPORT_EFFECT);
  bool get supportFlash => ((supportedFeatures &
  LightEntity.SUPPORT_FLASH) ==
      LightEntity.SUPPORT_FLASH);
  bool get supportColor => ((supportedFeatures &
  LightEntity.SUPPORT_COLOR) ==
      LightEntity.SUPPORT_COLOR);
  bool get supportTransition => ((supportedFeatures &
  LightEntity.SUPPORT_TRANSITION) ==
      LightEntity.SUPPORT_TRANSITION);
  bool get supportWhiteValue => ((supportedFeatures &
  LightEntity.SUPPORT_WHITE_VALUE) ==
      LightEntity.SUPPORT_WHITE_VALUE);

  int get brightness => _getIntAttributeValue("brightness");
  String get effect => attributes["effect"];
  int get colorTemp => _getIntAttributeValue("color_temp");
  double get maxMireds => _getDoubleAttributeValue("max_mireds");
  double get minMireds => _getDoubleAttributeValue("min_mireds");
  HSVColor get color => _getColor();
  bool get isAdditionalControls => ((supportedFeatures != null) && (supportedFeatures != 0));
  List<String> get effectList => getStringListAttributeValue("effect_list");

  LightEntity(Map rawData) : super(rawData);

  HSVColor _getColor() {
    List hs = attributes["hs_color"];
    try {
      if ((hs != null) && (hs.length > 0)) {
        double sat = hs[1]/100;
        String ssat = sat.toStringAsFixed(2);
        return HSVColor.fromAHSV(1.0, hs[0], double.parse(ssat), 1.0);
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
    if (!isAdditionalControls || state == EntityState.unavailable) {
      return Container(height: 0.0, width: 0.0);
    } else {
      return LightControlsWidget();
    }
  }

}