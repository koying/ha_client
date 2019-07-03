part of '../main.dart';

class NotificationEntity extends Entity {
  int get id => entityId.split(".")[1].hashCode;
  String get title => getAttribute("title");
  String get message => getAttribute("message");

  Future _showNotification() async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
        'ha_notify', 'Home Assistant notifications', 'Notifications from Home Assistant notify service',
        importance: Importance.Max, priority: Priority.High);
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      id,
      title ?? appName,
      message,
      platformChannelSpecifics,
      payload: entityId
    );
  }

  Future _cancelNotification() async {
    Logger.d("NotificationEntity cancelling: " + entityId);
    await Connection().callService(domain: "persistent_notification", service: "dismiss", additionalServiceData: {"notification_id": entityId.split(".")[1]});
    await flutterLocalNotificationsPlugin.cancel(
      id,
    );
  }

  NotificationEntity(Map rawData, String webHost) : super(rawData, webHost)
  {
     Logger.d("NotificationEntity creation: " + jsonEncode(rawData));
     _showNotification();
  }

  @override
  void update(Map rawData, String webHost) {
    super.update(rawData, webHost);
    Logger.d("NotificationEntity update: " + jsonEncode(rawData));
  }

  @override
  void dtor() {
    super.dtor();
    _cancelNotification();
  }
}
