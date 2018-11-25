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

class EntityTapAction {
  static const moreInfo = 'more-info';
  static const toggle = 'toggle';
  static const callService = 'call-service';
  static const none = 'none';
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