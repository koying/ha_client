part of 'main.dart';

class AuthManager {

  static final AuthManager _instance = AuthManager._internal();

  factory AuthManager() {
    return _instance;
  }

  AuthManager._internal();

  Future getTempToken({String oauthUrl}) {
    Completer completer = Completer();
    final flutterWebviewPlugin = new FlutterWebviewPlugin();
    flutterWebviewPlugin.onUrlChanged.listen((String url) {
      if (url.startsWith("http://ha-client.homemade.systems/service/auth_callback.html")) {
        String authCode = url.split("=")[1];
        Logger.d("We have auth code. Getting temporary access token...");
        Connection().sendHTTPPost(
            endPoint: "/auth/token",
            contentType: "application/x-www-form-urlencoded",
            includeAuthHeader: false,
            data: "grant_type=authorization_code&code=$authCode&client_id=${Uri.encodeComponent('http://ha-client.homemade.systems/')}"
        ).then((response) {
          Logger.d("Gottemp token");
          String tempToken = json.decode(response)['access_token'];
          Logger.d("Closing webview...");
          flutterWebviewPlugin.close();
          completer.complete(tempToken);
        }).catchError((e) {
          flutterWebviewPlugin.close();
          completer.completeError({"errorCode": 61, "errorMessage": "Error getting temp token"});
          Logger.e("Error getting temp token: ${e.toString()}");
        });
      }
    });
    Logger.d("Launching OAuth...");
    eventBus.fire(StartAuthEvent(oauthUrl));
    return completer.future;
  }

}