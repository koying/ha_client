part of '../main.dart';

class TrackerEntity extends Entity {
  double get latitude => _getDoubleAttributeValue("latitude");
  double get longitude => _getDoubleAttributeValue("longitude");
  int get accuracy => _getIntAttributeValue("gps_accuracy");
  bool isThis = false;

  TrackerEntity(Map rawData, String webHost) : super(rawData, webHost)
  {
    String deviceName = HomeAssistant()._getAppRegistrationData()["device_name"];
    deviceName = deviceName.replaceAll(new RegExp("[^A-Za-z0-9]"), "_").toLowerCase();
    if (entityId.indexOf(deviceName) != -1)
      isThis = true;

    Logger.d("TrackerEntity: " + entityId + " / " + deviceName);
    HAUtils.updateTracker(this);
  }

  @override
  void update(Map rawData, String webHost) {
    super.update(rawData, webHost);

    HAUtils.updateTracker(this);
  }

}
