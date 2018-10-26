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

  static void error(String message) {
    _writeToLog("Error", message);
  }

  static void warning(String message) {
    _writeToLog("Warning", message);
  }

  static void debug(String message) {
    _writeToLog("Debug", message);
  }

  static void _writeToLog(String level, String message) {
    if (isInDebugMode) {
      debugPrint('$message');
    }
    DateTime t = DateTime.now();
    _log.add("${formatDate(t, ["mm","dd"," ","HH",":","nn",":","ss"])} [$level] :  $message");
    if (_log.length > 100) {
      _log.removeAt(0);
    }
  }

}

class HAUtils {
  static void launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      TheLogger.error( "Could not launch $url");
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
  Map<String, dynamic> additionalParams;

  ServiceCallEvent(this.domain, this.service, this.entityId, this.additionalParams);
}

class ShowEntityPageEvent {
  Entity entity;

  ShowEntityPageEvent(this.entity);
}

class ShowErrorEvent {
  String text;
  int errorCode;

  ShowErrorEvent(this.text, this.errorCode);
}