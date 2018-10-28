part of '../main.dart';

class SunEntity extends Entity {
  SunEntity(Map rawData) : super(rawData);
}

class SensorEntity extends Entity {

  @override
  int historyWidgetType = EntityHistoryWidgetType.valueToTime;

  SensorEntity(Map rawData) : super(rawData);

}