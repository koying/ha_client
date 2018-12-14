part of '../main.dart';

class EntityState {
  static const on = 'on';
  static const off = 'off';
  static const home = 'home';
  static const not_home = 'not_home';
  static const unknown = 'unknown';
  static const open = 'open';
  static const opening = 'opening';
  static const closed = 'closed';
  static const closing = 'closing';
  static const playing = 'playing';
  static const paused = 'paused';
  static const idle = 'idle';
  static const standby = 'standby';
  static const alarm_disarmed = 'disarmed';
  static const alarm_armed_home = 'armed_home';
  static const alarm_armed_away = 'armed_away';
  static const alarm_armed_night = 'armed_night';
  static const alarm_armed_custom_bypass = 'armed_custom_bypass';
  static const alarm_pending = 'pending';
  static const alarm_arming = 'arming';
  static const alarm_disarming = 'disarming';
  static const alarm_triggered = 'triggered';
  static const locked = 'locked';
  static const unlocked = 'unlocked';
  static const unavailable = 'unavailable';
  static const ok = 'ok';
  static const problem = 'problem';
}

class EntityUIAction {
  static const moreInfo = 'more-info';
  static const toggle = 'toggle';
  static const callService = 'call-service';
  static const navigate = 'navigate';
  static const none = 'none';

  String tapAction = EntityUIAction.moreInfo;
  String tapNavigationPath;
  String tapService;
  Map<String, dynamic> tapServiceData;
  String holdAction = EntityUIAction.none;
  String holdNavigationPath;
  String holdService;
  Map<String, dynamic> holdServiceData;

  EntityUIAction({rawEntityData}) {
    if (rawEntityData != null) {
      if (rawEntityData["tap_action"] != null) {
        if (rawEntityData["tap_action"] is String) {
          tapAction = rawEntityData["tap_action"];
        } else {
          tapAction =
              rawEntityData["tap_action"]["action"] ?? EntityUIAction.moreInfo;
          tapNavigationPath = rawEntityData["tap_action"]["navigation_path"];
          tapService = rawEntityData["tap_action"]["service"];
          tapServiceData = rawEntityData["tap_action"]["service_data"];
        }
      }
      if (rawEntityData["hold_action"] != null) {
        if (rawEntityData["hold_action"] is String) {
          holdAction = rawEntityData["hold_action"];
        } else {
          holdAction =
              rawEntityData["hold_action"]["action"] ?? EntityUIAction.none;
          holdNavigationPath = rawEntityData["hold_action"]["navigation_path"];
          holdService = rawEntityData["hold_action"]["service"];
          holdServiceData = rawEntityData["hold_action"]["service_data"];
        }
      }
    }
  }

}

class CardType {
  static const horizontalStack = "horizontal-stack";
  static const verticalStack = "vertical-stack";
  static const entities = "entities";
  static const glance = "glance";
  static const mediaControl = "media-control";
  static const weatherForecast = "weather-forecast";
  static const thermostat = "thermostat";
  static const sensor = "sensor";
  static const plantStatus = "plant-status";
  static const pictureEntity = "picture-entity";
  static const pictureElements = "picture-elements";
  static const picture = "picture";
  static const map = "map";
  static const iframe = "iframe";
  static const gauge = "gauge";
  static const entityButton = "entity-button";
  static const conditional = "conditional";
  static const alarmPanel = "alarm-panel";
}