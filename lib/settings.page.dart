part of 'main.dart';

class ConnectionSettingsPage extends StatefulWidget {
  ConnectionSettingsPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ConnectionSettingsPageState createState() => new _ConnectionSettingsPageState();
}

class _ConnectionSettingsPageState extends State<ConnectionSettingsPage> {
  String _hassioDomain = "";
  String _newHassioDomain = "";
  String _hassioPort = "";
  String _newHassioPort = "";
  String _hassioPassword = "";
  String _newHassioPassword = "";
  String _socketProtocol = "wss";
  String _newSocketProtocol = "wss";
  String _authType = "access_token";
  String _newAuthType = "access_token";
  bool _useLovelace = false;
  bool _newUseLovelace = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _hassioDomain = _newHassioDomain = prefs.getString("hassio-domain")?? "";
      _hassioPort = _newHassioPort = prefs.getString("hassio-port") ?? "";
      _hassioPassword = _newHassioPassword = prefs.getString("hassio-password") ?? "";
      _socketProtocol = _newSocketProtocol = prefs.getString("hassio-protocol") ?? 'wss';
      _authType = _newAuthType = prefs.getString("hassio-auth-type") ?? 'access_token';
      try {
        _useLovelace = _newUseLovelace = prefs.getBool("use-lovelace") ?? false;
      } catch (e) {
        _useLovelace = _newUseLovelace = false;
      }
    });
  }

  bool _checkConfigChanged() {
    return ((_newHassioPassword != _hassioPassword) ||
      (_newHassioPort != _hassioPort) ||
      (_newHassioDomain != _hassioDomain) ||
      (_newSocketProtocol != _socketProtocol) ||
      (_newAuthType != _authType) ||
      (_newUseLovelace != _useLovelace));

  }

  _saveSettings() async {
    if (_newHassioDomain.indexOf("http") == 0 && _newHassioDomain.indexOf("//") > 0) {
      _newHassioDomain = _newHassioDomain.split("//")[1];
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("hassio-domain", _newHassioDomain);
    prefs.setString("hassio-port", _newHassioPort);
    prefs.setString("hassio-password", _newHassioPassword);
    prefs.setString("hassio-protocol", _newSocketProtocol);
    prefs.setString("hassio-res-protocol", _newSocketProtocol == "wss" ? "https" : "http");
    prefs.setString("hassio-auth-type", _newAuthType);
    prefs.setBool("use-lovelace", _newUseLovelace);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
          Navigator.pop(context);
        }),
        title: new Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: (){
              if (_checkConfigChanged()) {
                TheLogger.debug("Settings changed. Saving...");
                _saveSettings().then((r) {
                  Navigator.pop(context);
                  eventBus.fire(SettingsChangedEvent(true));
                });
              } else {
                TheLogger.debug("Settings was not changed");
                Navigator.pop(context);
              }
            }
          )
        ],
      ),
      body: ListView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          Text(
              "Connection settings",
              style: TextStyle(
                color: Colors.black45,
                fontSize: 20.0
              ),
          ),
          new Row(
            children: [
              Text("Use ssl (HTTPS)"),
              Switch(
                value: (_newSocketProtocol == "wss"),
                onChanged: (value) {
                  setState(() {
                    _newSocketProtocol = value ? "wss" : "ws";
                  });
                },
              )
            ],
          ),
          new TextField(
            decoration: InputDecoration(
              labelText: "Home Assistant domain or ip address"
            ),
            controller: new TextEditingController.fromValue(
                new TextEditingValue(
                    text: _newHassioDomain,
                    selection:
                    new TextSelection.collapsed(offset: _newHassioDomain.length)
                )
            ),
            onChanged: (value) {
              _newHassioDomain = value;
            }
          ),
          new TextField(
            decoration: InputDecoration(
              labelText: "Home Assistant port (default is 8123)"
            ),
            controller: new TextEditingController.fromValue(
                new TextEditingValue(
                    text: _newHassioPort,
                    selection:
                    new TextSelection.collapsed(offset: _newHassioPort.length)
                )
            ),
            onChanged: (value) {
              _newHassioPort = value;
            }
          ),
          new Text(
            "Try ports 80 and 443 if default is not working and you don't know why.",
            style: TextStyle(color: Colors.grey),
          ),
          new Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  "Login with access token (HA >= 0.78.0)",
                  softWrap: true,
                  maxLines: 2,
                ),
              ),
              Switch(
                value: (_newAuthType == "access_token"),
                onChanged: (value) {
                  setState(() {
                    _newAuthType = value ? "access_token" : "api_password";
                  });
                },
              )
            ],
          ),
          new Text(
            "You should use access token for HA >= 0.84.1. Legacy password will not work there.",
            style: TextStyle(color: Colors.grey),
          ),
          new TextField(
            decoration: InputDecoration(
                labelText: _newAuthType == "access_token" ? "Access token" : "API password"
            ),
            controller: new TextEditingController.fromValue(
                new TextEditingValue(
                    text: _newHassioPassword,
                    selection:
                    new TextSelection.collapsed(offset: _newHassioPassword.length)
                )
            ),
            onChanged: (value) {
              _newHassioPassword = value;
            }
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: Text(
              "UI",
              style: TextStyle(
                  color: Colors.black45,
                  fontSize: 20.0
              ),
            ),
          ),
          new Row(
            children: [
              Text("Use Lovelace UI"),
              Switch(
                value: _newUseLovelace,
                onChanged: (value) {
                  setState(() {
                    _newUseLovelace = value;
                  });
                },
              )
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
