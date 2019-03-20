part of 'main.dart';

class Logger {

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

  static void e(String message) {
    _writeToLog("Error", message);
  }

  static void w(String message) {
    _writeToLog("Warning", message);
  }

  static void d(String message) {
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
    if (await urlLauncher.canLaunch(url)) {
      await urlLauncher.launch(url);
    } else {
      Logger.e( "Could not launch $url");
    }
  }

  static void launchURLInCustomTab(BuildContext context, String url) async {
    try {
      await launch(
        "$url",
        option: new CustomTabsOption(
          toolbarColor: Theme.of(context).primaryColor,
          enableDefaultShare: true,
          enableUrlBarHiding: true,
          showPageTitle: true,
          animation: new CustomTabsAnimation.slideIn()
          // or user defined animation.
          /*animation: new CustomTabsAnimation(
          startEnter: 'slide_up',
          startExit: 'android:anim/fade_out',
          endEnter: 'android:anim/fade_in',
          endExit: 'slide_down',
        )*/,
        extraCustomTabs: <String>[
          // ref. https://play.google.com/store/apps/details?id=org.mozilla.firefox
          'org.mozilla.firefox',
          // ref. https://play.google.com/store/apps/details?id=com.microsoft.emmx
          'com.microsoft.emmx',
        ],
      ),
    );
    } catch (e) {
      Logger.w("Can't open custom tab: ${e.toString()}");
      Logger.w("Launching in default browser");
      HAUtils.launchURL(url);
    }
  }
}

class StateChangedEvent {
  String entityId;
  String newState;
  bool needToRebuildUI;

  StateChangedEvent({
    this.entityId,
    this.newState,
    this.needToRebuildUI: false
  });
}

class SettingsChangedEvent {
  bool reconnect;

  SettingsChangedEvent(this.reconnect);
}

class RefreshDataFinishedEvent {
  RefreshDataFinishedEvent();
}

class ReloadUIEvent {
  ReloadUIEvent();
}

class StartAuthEvent {
  String oauthUrl;

  StartAuthEvent(this.oauthUrl);
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