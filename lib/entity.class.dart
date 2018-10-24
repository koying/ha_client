part of 'main.dart';

class Entity {
  static const STATE_ICONS_COLORS = {
    "on": Colors.amber,
    "off": Color.fromRGBO(68, 115, 158, 1.0),
    "default": Color.fromRGBO(68, 115, 158, 1.0),
    "unavailable": Colors.black12,
    "unknown": Colors.black12,
    "playing": Colors.amber
  };
  static const badgeColors = {
    "default": Color.fromRGBO(223, 76, 30, 1.0),
    "binary_sensor": Color.fromRGBO(3, 155, 229, 1.0)
  };
  static List badgeDomains = [
    "alarm_control_panel",
    "binary_sensor",
    "device_tracker",
    "updater",
    "sun",
    "timer",
    "sensor"
  ];

  static const rightWidgetPadding = 14.0;
  static const leftWidgetPadding = 8.0;
  static const extendedWidgetHeight = 50.0;
  static const iconSize = 28.0;
  static const stateFontSize = 16.0;
  static const nameFontSize = 16.0;
  static const smallFontSize = 14.0;
  static const largeFontSize = 24.0;
  static const inputWidth = 160.0;
  static const rowPadding = 10.0;

  double widgetHeight = 34.0;

  Map attributes;
  String domain;
  String entityId;
  String state;
  String assumedState;
  DateTime _lastUpdated;

  List<Entity> childEntities = [];

  List<String> attributesToShow = ["all"];

  String get displayName =>
      attributes["friendly_name"] ?? (attributes["name"] ?? "_");

  String get deviceClass => attributes["device_class"] ?? null;
  bool get isView =>
      (domain == "group") &&
      (attributes != null ? attributes["view"] ?? false : false);
  bool get isGroup => domain == "group";
  bool get isBadge => Entity.badgeDomains.contains(domain);
  String get icon => attributes["icon"] ?? "";
  bool get isOn => state == "on";
  String get entityPicture => attributes["entity_picture"];
  String get unitOfMeasurement => attributes["unit_of_measurement"] ?? "";
  List get childEntityIds => attributes["entity_id"] ?? [];
  String get lastUpdated => _getLastUpdatedFormatted();
  bool get isHidden => attributes["hidden"] ?? false;

  Entity(Map rawData) {
    update(rawData);
  }

  void update(Map rawData) {
    attributes = rawData["attributes"] ?? {};
    domain = rawData["entity_id"].split(".")[0];
    entityId = rawData["entity_id"];
    state = rawData["state"];
    assumedState = state;
    _lastUpdated = DateTime.tryParse(rawData["last_updated"]);
  }

  double _getDoubleAttributeValue(String attributeName) {
    var temp1 = attributes["$attributeName"];
    if (temp1 is int) {
      return temp1.toDouble();
    } else if (temp1 is double) {
      return temp1;
    } else {
      return double.tryParse("$temp1");
    }
  }

  int _getIntAttributeValue(String attributeName) {
    var temp1 = attributes["$attributeName"];
    if (temp1 is int) {
      return temp1;
    } else if (temp1 is double) {
      return temp1.round();
    } else {
      return int.tryParse("$temp1");
    }
  }

  Widget buildDefaultWidget(BuildContext context) {
    return EntityModel(
      entity: this,
      child: DefaultEntityContainer(
          state: _buildStatePart(context),
          height: widgetHeight,
      ),
      handleTap: true,
    );
  }

  Widget _buildStatePart(BuildContext context) {
    return SimpleEntityState();
  }

  Widget _buildStatePartForPage(BuildContext context) {
    return _buildStatePart(context);
  }

  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return Container(
      width: 0.0,
      height: 0.0,
    );
  }

  Widget buildEntityPageWidget(BuildContext context) {
    return EntityModel(
      entity: this,
      child: EntityPageContainer(children: <Widget>[
        DefaultEntityContainer(state: _buildStatePartForPage(context), height: widgetHeight),
        LastUpdatedWidget(),
        Divider(),
        _buildAdditionalControlsForPage(context),
        Divider(),
        EntityAttributesList()
      ]),
      handleTap: false,
    );
  }

  Widget buildBadgeWidget(BuildContext context) {
    return EntityModel(
      entity: this,
      child: Badge(),
      handleTap: true,
    );
  }

  String getAttribute(String attributeName) {
    if (attributes != null) {
      return attributes["$attributeName"];
    }
    return null;
  }

  String _getLastUpdatedFormatted() {
    if (_lastUpdated == null) {
      return "-";
    } else {
      DateTime now = DateTime.now();
      Duration d = now.difference(_lastUpdated);
      String text;
      int v;
      if (d.inDays == 0) {
        if (d.inHours == 0) {
          if (d.inMinutes == 0) {
            text = "seconds ago";
            v = d.inSeconds;
          } else {
            text = "minutes ago";
            v = d.inMinutes;
          }
        } else {
          text = "hours ago";
          v = d.inHours;
        }
      } else {
        text = "days ago";
        v = d.inDays;
      }
      return "$v $text";
    }
  }
}

class SwitchEntity extends Entity {
  SwitchEntity(Map rawData) : super(rawData);

  @override
  Widget _buildStatePart(BuildContext context) {
    return SwitchStateWidget();
  }
}

class ButtonEntity extends Entity {
  ButtonEntity(Map rawData) : super(rawData);

  @override
  Widget _buildStatePart(BuildContext context) {
    return ButtonStateWidget();
  }
}

class TextEntity extends Entity {
  TextEntity(Map rawData) : super(rawData);

  int get valueMinLength => attributes["min"] ?? -1;
  int get valueMaxLength => attributes["max"] ?? -1;
  String get valuePattern => attributes["pattern"] ?? null;
  bool get isTextField => attributes["mode"] == "text";
  bool get isPasswordField => attributes["mode"] == "password";

  @override
  Widget _buildStatePart(BuildContext context) {
    return TextInputStateWidget();
  }
}

class SunEntity extends Entity {
  SunEntity(Map rawData) : super(rawData);
}

class SliderEntity extends Entity {
  SliderEntity(Map rawData) : super(rawData);

  double get minValue => attributes["min"] ?? 0.0;
  double get maxValue => attributes["max"] ?? 100.0;
  double get valueStep => attributes["step"] ?? 1.0;
  double get doubleState => double.tryParse(state) ?? 0.0;

  @override
  Widget _buildStatePart(BuildContext context) {
    return Expanded(
      //width: 200.0,
      child: Row(
        children: <Widget>[
          SliderStateWidget(
            expanded: true,
          ),
          SimpleEntityState(),
        ],
      ),
    );
  }

  @override
  Widget _buildStatePartForPage(BuildContext context) {
    return SimpleEntityState();
  }

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return SliderStateWidget(
      expanded: false,
    );
  }
}

class ClimateEntity extends Entity {
  @override
  double widgetHeight = 38.0;

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

class SelectEntity extends Entity {
  List<String> get listOptions => attributes["options"] != null
      ? (attributes["options"] as List).cast<String>()
      : [];

  SelectEntity(Map rawData) : super(rawData);

  @override
  Widget _buildStatePart(BuildContext context) {
    return SelectControlWidget();
  }
}

class DateTimeEntity extends Entity {
  bool get hasDate => attributes["has_date"] ?? false;
  bool get hasTime => attributes["has_time"] ?? false;
  int get year => attributes["year"] ?? 1970;
  int get month => attributes["month"] ?? 1;
  int get day => attributes["day"] ?? 1;
  int get hour => attributes["hour"] ?? 0;
  int get minute => attributes["minute"] ?? 0;
  int get second => attributes["second"] ?? 0;
  String get formattedState => _getFormattedState();
  DateTime get dateTimeState => _getDateTimeState();

  DateTimeEntity(Map rawData) : super(rawData);

  @override
  Widget _buildStatePart(BuildContext context) {
    return DateTimeStateWidget();
  }

  DateTime _getDateTimeState() {
    return DateTime(
        this.year, this.month, this.day, this.hour, this.minute, this.second);
  }

  String _getFormattedState() {
    String formattedState = "";
    if (this.hasDate) {
      formattedState += formatDate(dateTimeState, [M, ' ', d, ', ', yyyy]);
    }
    if (this.hasTime) {
      formattedState += " " + formatDate(dateTimeState, [HH, ':', nn]);
    }
    return formattedState;
  }

  void setNewState(newValue) {
    eventBus
        .fire(new ServiceCallEvent(domain, "set_datetime", entityId, newValue));
  }
}

class CoverEntity extends Entity {
  @override
  double widgetHeight = 38.0;

  static const SUPPORT_OPEN = 1;
  static const SUPPORT_CLOSE = 2;
  static const SUPPORT_SET_POSITION = 4;
  static const SUPPORT_STOP = 8;
  static const SUPPORT_OPEN_TILT = 16;
  static const SUPPORT_CLOSE_TILT = 32;
  static const SUPPORT_STOP_TILT = 64;
  static const SUPPORT_SET_TILT_POSITION = 128;

  bool get supportOpen => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_OPEN) ==
      CoverEntity.SUPPORT_OPEN);
  bool get supportClose => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_CLOSE) ==
      CoverEntity.SUPPORT_CLOSE);
  bool get supportSetPosition => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_SET_POSITION) ==
      CoverEntity.SUPPORT_SET_POSITION);
  bool get supportStop => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_STOP) ==
      CoverEntity.SUPPORT_STOP);

  bool get supportOpenTilt => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_OPEN_TILT) ==
      CoverEntity.SUPPORT_OPEN_TILT);
  bool get supportCloseTilt => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_CLOSE_TILT) ==
      CoverEntity.SUPPORT_CLOSE_TILT);
  bool get supportStopTilt => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_STOP_TILT) ==
      CoverEntity.SUPPORT_STOP_TILT);
  bool get supportSetTiltPosition => ((attributes["supported_features"] &
  CoverEntity.SUPPORT_SET_TILT_POSITION) ==
      CoverEntity.SUPPORT_SET_TILT_POSITION);


  double get currentPosition => _getDoubleAttributeValue('current_position');
  double get currentTiltPosition => _getDoubleAttributeValue('current_tilt_position');
  bool get canBeOpened => ((state != "opening") && (state != "open"));
  bool get canBeClosed => ((state != "closing") && (state != "closed"));
  bool get canTiltBeOpened => currentPosition < 100;
  bool get canTiltBeClosed => currentPosition > 0;

  CoverEntity(Map rawData) : super(rawData);

  @override
  Widget _buildStatePart(BuildContext context) {
    return CoverEntityControlState();
  }

  @override
  Widget _buildAdditionalControlsForPage(BuildContext context) {
    return CoverControlWidget();
  }

}

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
  int get colorTemp => _getIntAttributeValue("color_temp");
  double get maxMireds => _getDoubleAttributeValue("max_mireds");
  double get minMireds => _getDoubleAttributeValue("min_mireds");
  Color get color => _getColor();
  bool get isAdditionalControls => ((attributes["supported_features"] != null) && (attributes["supported_features"] != 0));
  List<String> get effectList => _getEffectList();

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

  List<String> _getEffectList() {
    if (attributes["effect_list"] != null) {
      List<String> result = (attributes["effect_list"] as List).cast<String>();
      return result;
    } else {
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
