part of '../main.dart';

class SunEntity extends Entity {
  SunEntity(Map rawData, String webHost) : super(rawData, webHost);
}

class SensorEntity extends Entity {

  @override
  EntityHistoryConfig historyConfig = EntityHistoryConfig(
      chartType: EntityHistoryWidgetType.numericState,
      numericState: true
  );

  SensorEntity(Map rawData, String webHost) : super(rawData, webHost);

}