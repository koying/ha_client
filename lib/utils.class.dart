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

class haUtils {
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

  StateChangedEvent(this.entityId);
}

class SettingsChangedEvent {
  bool reconnect;

  SettingsChangedEvent(this.reconnect);
}