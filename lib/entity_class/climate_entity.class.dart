part of '../main.dart';

class ClimateEntity extends Entity {
  @override
  double widgetHeight = 38.0;

  @override
  EntityHistoryConfig historyConfig = EntityHistoryConfig(
    chartType: EntityHistoryWidgetType.numericAttributes,
    numericState: false,
    numericAttributesToShow: ["temperature", "current_temperature"]
  );

  static const SUPPORT_TARGET_TEMPERATURE = 1;
  static const SUPPORT_TARGET_TEMPERATURE_HIGH = 2;
  static const SUPPORT_TARGET_TEMPERATURE_LOW = 4;
  static const SUPPORT_TARGET_HUMIDITY = 8;
  static const SUPPORT_TARGET_HUMIDITY_HIGH = 16;
  static const SUPPORT_TARGET_HUMIDITY_LOW = 32;
  static const SUPPORT_FAN_MODE = 64;
  static const SUPPORT_OPERATION_MODE = 128;
  static const SUPPORT_HOLD_MODE = 256;
  static const SUPPORT_SWING_MODE = 512;
  static const SUPPORT_AWAY_MODE = 1024;
  static const SUPPORT_AUX_HEAT = 2048;
  static const SUPPORT_ON_OFF = 4096;

  bool get supportTargetTemperature => ((attributes["supported_features"] &
  ClimateEntity.SUPPORT_TARGET_TEMPERATURE) ==
      ClimateEntity.SUPPORT_TARGET_TEMPERATURE);
  bool get supportTargetTemperatureHigh => ((attributes["supported_features"] &
  ClimateEntity.SUPPORT_TARGET_TEMPERATURE_HIGH) ==
      ClimateEntity.SUPPORT_TARGET_TEMPERATURE_HIGH);
  bool get supportTargetTemperatureLow => ((attributes["supported_features"] &
  ClimateEntity.SUPPORT_TARGET_TEMPERATURE_LOW) ==
      ClimateEntity.SUPPORT_TARGET_TEMPERATURE_LOW);
  bool get supportTargetHumidity => ((attributes["supported_features"] &
  ClimateEntity.SUPPORT_TARGET_HUMIDITY) ==
      ClimateEntity.SUPPORT_TARGET_HUMIDITY);
  bool get supportTargetHumidityHigh => ((attributes["supported_features"] &
  ClimateEntity.SUPPORT_TARGET_HUMIDITY_HIGH) ==
      ClimateEntity.SUPPORT_TARGET_HUMIDITY_HIGH);
  bool get supportTargetHumidityLow => ((attributes["supported_features"] &
  ClimateEntity.SUPPORT_TARGET_HUMIDITY_LOW) ==
      ClimateEntity.SUPPORT_TARGET_HUMIDITY_LOW);
  bool get supportFanMode =>
      ((attributes["supported_features"] & ClimateEntity.SUPPORT_FAN_MODE) ==
          ClimateEntity.SUPPORT_FAN_MODE);
  bool get supportOperationMode => ((attributes["supported_features"] &
  ClimateEntity.SUPPORT_OPERATION_MODE) ==
      ClimateEntity.SUPPORT_OPERATION_MODE);
  bool get supportHoldMode =>
      ((attributes["supported_features"] & ClimateEntity.SUPPORT_HOLD_MODE) ==
          ClimateEntity.SUPPORT_HOLD_MODE);
  bool get supportSwingMode =>
      ((attributes["supported_features"] & ClimateEntity.SUPPORT_SWING_MODE) ==
          ClimateEntity.SUPPORT_SWING_MODE);
  bool get supportAwayMode =>
      ((attributes["supported_features"] & ClimateEntity.SUPPORT_AWAY_MODE) ==
          ClimateEntity.SUPPORT_AWAY_MODE);
  bool get supportAuxHeat =>
      ((attributes["supported_features"] & ClimateEntity.SUPPORT_AUX_HEAT) ==
          ClimateEntity.SUPPORT_AUX_HEAT);
  bool get supportOnOff =>
      ((attributes["supported_features"] & ClimateEntity.SUPPORT_ON_OFF) ==
          ClimateEntity.SUPPORT_ON_OFF);

  List<String> get operationList => attributes["operation_list"] != null
      ? (attributes["operation_list"] as List).cast<String>()
      : null;
  List<String> get fanList => attributes["fan_list"] != null
      ? (attributes["fan_list"] as List).cast<String>()
      : null;
  List<String> get swingList => attributes["swing_list"] != null
      ? (attributes["swing_list"] as List).cast<String>()
      : null;
  double get temperature => _getDoubleAttributeValue('temperature');
  double get targetHigh => _getDoubleAttributeValue('target_temp_high');
  double get targetLow => _getDoubleAttributeValue('target_temp_low');
  double get maxTemp => _getDoubleAttributeValue('max_temp') ?? 100.0;
  double get minTemp => _getDoubleAttributeValue('min_temp') ?? -100.0;
  double get targetHumidity => _getDoubleAttributeValue('humidity');
  double get maxHumidity => _getDoubleAttributeValue('max_humidity');
  double get minHumidity => _getDoubleAttributeValue('min_humidity');
  String get operationMode => attributes['operation_mode'];
  String get fanMode => attributes['fan_mode'];
  String get swingMode => attributes['swing_mode'];
  bool get awayMode => attributes['away_mode'] == "on";
  bool get isOff => state == "off";
  bool get auxHeat => attributes['aux_heat'] == "on";

  ClimateEntity(Map rawData) : super(rawData);

  @override
  Widget _buildStatePart(BuildContext context) {
    return ClimateStateWidget();
  }

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return ClimateControlWidget();
  }

  @override
  double _getDoubleAttributeValue(String attributeName) {
    var temp1 = attributes["$attributeName"];
    if (temp1 is int) {
      return temp1.toDouble();
    } else if (temp1 is double) {
      return temp1;
    } else {
      return null;
    }
  }

}