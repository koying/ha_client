part of 'main.dart';

class Device {

  static final Device _instance = Device._internal();

  factory Device() {
    return _instance;
  }

  String unicDeviceId;
  String manufacturer;
  String model;
  String osName;
  String osVersion;

  Device._internal();

  loadDeviceInfo() {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    deviceInfo.androidInfo.then((androidInfo) {
      unicDeviceId = "${androidInfo.model.toLowerCase().replaceAll(' ', '_')}_${androidInfo.androidId}";
      manufacturer = "${androidInfo.manufacturer}";
      model = "${androidInfo.model}";
      osName = "Android";
      osVersion = "${androidInfo.version.release}";
    });
  }
}