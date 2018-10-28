part of '../main.dart';

class SunEntity extends Entity {
  SunEntity(Map rawData) : super(rawData);
}

class SensorEntity extends Entity {

  @override
  EntityHistoryConfig historyConfig = EntityHistoryConfig(
      chartType: EntityHistoryWidgetType.numericState,
      numericState: true
  );

  SensorEntity(Map rawData) : super(rawData);

}