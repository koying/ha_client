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

class HAError {
  String message;
  final List<HAErrorAction> actions;

  HAError(this.message, {this.actions: const [HAErrorAction.tryAgain()]});

  HAError.unableToConnect({this.actions = const [HAErrorAction.tryAgain()]}) {
    this.message = "Unable to connect to Home Assistant";
  }

  HAError.disconnected({this.actions = const [HAErrorAction.reconnect()]}) {
    this.message = "Disconnected";
  }

  HAError.checkConnectionSettings({this.actions = const [HAErrorAction.reload(), HAErrorAction(title: "Settings", type: HAErrorActionType.OPEN_CONNECTION_SETTINGS)]}) {
    this.message = "Check connection settings";
  }
}

class HAErrorAction {
  final String title;
  final int type;
  final String url;

  const HAErrorAction({@required this.title, this.type: HAErrorActionType.FULL_RELOAD, this.url});

  const HAErrorAction.tryAgain({this.title = "Try again", this.type = HAErrorActionType.FULL_RELOAD, this.url});

  const HAErrorAction.reconnect({this.title = "Reconnect", this.type = HAErrorActionType.FULL_RELOAD, this.url});

  const HAErrorAction.reload({this.title = "Reload", this.type = HAErrorActionType.FULL_RELOAD, this.url});

  const HAErrorAction.loginAgain({this.title = "Login again", this.type = HAErrorActionType.FULL_RELOAD, this.url});

}

class HAErrorActionType {
  static const FULL_RELOAD = 0;
  static const QUICK_RELOAD = 1;
  static const LOGOUT = 2;
  static const URL = 3;
  static const OPEN_CONNECTION_SETTINGS = 4;
}

class HAUtils {
  static const _channel = const MethodChannel('com.keyboardcrumbs.hassclient/main');

  static void launchURL(String url) async {
    if (await urlLauncher.canLaunch(url)) {
      await urlLauncher.launch(url);
    } else {
      Logger.e( "Could not launch $url");
    }
  }

  //Launch an activity
  static Future<bool> launchActivity(
      String classString) async {
    assert(classString != null);
    final bool result = await _channel.invokeMethod<bool>(
      'launch',
      <String, Object>{
        'class': classString,
      },
    );
    return result;
  }

  //Launch Map Activity
  static Future<bool> launchMap() async {
    final bool result = await _channel.invokeMethod<bool>(
      'launchMap',
      <String, Object>{
      },
    );
    return result;
  }

  //Launch Update Tracker intent
  static Future<bool> updateTracker(TrackerEntity tracker) async {
    if (tracker.latitude == null || tracker.longitude == null || tracker.accuracy == null)
      return false;

    final bool result = await _channel.invokeMethod<bool>(
      'updateTracker',
      <String, Object>{
        "id": tracker.entityId,
        "description": tracker.displayName,
        "longitude": tracker.longitude,
        "latitude": tracker.latitude,
        "accuracy": tracker.accuracy,
        "icon": MaterialDesignIcons.getIconCodeByIconName(tracker.icon),
        "picture_url": tracker.entityPicture,
        "isThis": tracker.isThis,
      },
    );
    return result;
  }

  static void launchURLInCustomTab({BuildContext context, String url, bool enableDefaultShare: true, bool showPageTitle: true}) async {
    try {
      await launch(
        "$url",
        option: new CustomTabsOption(
          toolbarColor: Theme.of(context).primaryColor,
          enableDefaultShare: enableDefaultShare,
          enableUrlBarHiding: true,
          showPageTitle: showPageTitle,
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
  bool showButton;

  StartAuthEvent(this.oauthUrl, this.showButton);
}

class ServiceCallEvent {
  String domain;
  String service;
  String entityId;
  Map<String, dynamic> additionalParams;

  ServiceCallEvent(this.domain, this.service, this.entityId, this.additionalParams);
}

class ShowDialogEvent {
  final String title;
  final String body;
  final String positiveText;
  final String negativeText;
  final  onPositive;
  final  onNegative;

  ShowDialogEvent({this.title, this.body, this.positiveText: "Ok", this.negativeText: "Cancel", this.onPositive, this.onNegative});
}

class ShowEntityPageEvent {
  Entity entity;

  ShowEntityPageEvent(this.entity);
}

class ShowErrorEvent {
  final HAError error;

  ShowErrorEvent(this.error);
}
