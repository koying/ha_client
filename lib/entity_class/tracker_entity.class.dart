part of '../main.dart';

class TrackerEntity extends Entity {
  double get latitude => _getDoubleAttributeValue("latitude");
  double get longitude => _getDoubleAttributeValue("longitude");
  int get accuracy => _getIntAttributeValue("gps_accuracy");

  TrackerEntity(Map rawData, String webHost) : super(rawData, webHost)
  {
    HAUtils.updateTracker(this);
  }

  @override
  void update(Map rawData, String webHost) {
    super.update(rawData, webHost);

    HAUtils.updateTracker(this);
  }

}
