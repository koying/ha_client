part of 'main.dart';

class TheLogger {

  static List<String> _log = [];

  static String getLog() {
    String res = '';
    _log.forEach((line) {
      res += "$line\n";
    });
    return res;
  }

  static bool get isInDebugMode {
    bool inDebugMode = false;

    assert(inDebugMode = true);

    return inDebugMode;
  }

  static void log(String level, String message) {
    if (isInDebugMode) {
      debugPrint('$message');
    }
    _log.add("[$level] :  $message");
    if (_log.length > 50) {
      _log.removeAt(0);
    }
  }

}

class HAUtils {
  static void launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      TheLogger.log("Error", "Could not launch $url");
    }
  }
}

class StateChangedEvent {
  String entityId;
  String newState;
  bool localChange;

  StateChangedEvent(this.entityId, this.newState, this.localChange);
}

class SettingsChangedEvent {
  bool reconnect;

  SettingsChangedEvent(this.reconnect);
}

class RefreshDataEvent {
  RefreshDataEvent();
}

class RefreshDataFinishedEvent {
  RefreshDataFinishedEvent();
}

class ServiceCallEvent {
  String domain;
  String service;
  String entityId;
  Map<String, String> additionalParams;

  ServiceCallEvent(this.domain, this.service, this.entityId, this.additionalParams);
}

class ShowEntityPageEvent {
  Entity entity;

  ShowEntityPageEvent(this.entity);
}