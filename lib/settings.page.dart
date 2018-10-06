part of 'main.dart';

class ConnectionSettingsPage extends StatefulWidget {
  ConnectionSettingsPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ConnectionSettingsPageState createState() => new _ConnectionSettingsPageState();
}

class _ConnectionSettingsPageState extends State<ConnectionSettingsPage> {
  String _hassioDomain = "";
  String _hassioPort = "";
  String _hassioPassword = "";
  String _socketProtocol = "wss";
  String _authType = "access_token";
  bool _edited = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _hassioDomain = prefs.getString("hassio-domain")?? "";
      _hassioPort = prefs.getString("hassio-port") ?? "";
      _hassioPassword = prefs.getString("hassio-password") ?? "";
      _socketProtocol = prefs.getString("hassio-protocol") ?? 'wss';
      _authType = prefs.getString("hassio-auth-type") ?? 'access_token';
    });
  }

  _saveSettings() async {
    if (_hassioDomain.indexOf("http") == 0 && _hassioDomain.indexOf("//") > 0) {
      _hassioDomain = _hassioDomain.split("//")[1];
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("hassio-domain", _hassioDomain);
    prefs.setString("hassio-port", _hassioPort);
    prefs.setString("hassio-password", _hassioPassword);
    prefs.setString("hassio-protocol", _socketProtocol);
    prefs.setString("hassio-res-protocol", _socketProtocol == "wss" ? "https" : "http");
    prefs.setString("hassio-auth-type", _authType);
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
            onPressed: _edited ? (){
                _saveSettings().then((r){
                  Navigator.pop(context);
                  eventBus.fire(SettingsChangedEvent(true));
                });
            } : null
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          new Row(
            children: [
              Text("Use ssl (HTTPS)"),
              Switch(
                value: (_socketProtocol == "wss"),
                onChanged: (value) {
                  setState(() {
                    _socketProtocol = value ? "wss" : "ws";
                    _edited = true;
                  });
                },
              )
            ],
          ),
          new TextField(
            decoration: InputDecoration(
              labelText: "Home Assistant domain or ip address"
            ),
            controller: TextEditingController(
              text: _hassioDomain
            ),
            onChanged: (value) {
              _hassioDomain = value;
            },
          ),
          new TextField(
            decoration: InputDecoration(
              labelText: "Home Assistant port (default is 8123)"
            ),
            controller: TextEditingController(
              text: _hassioPort
            ),
            onChanged: (value) {
              _hassioPort = value;
              //_saveSettings();
            },
          ),
          new Row(
            children: [
              Text("Login with access token (HA >= 0.78.0)"),
              Switch(
                value: (_authType == "access_token"),
                onChanged: (value) {
                  setState(() {
                    _authType = value ? "access_token" : "api_password";
                    _edited = true;
                  });
                  //_saveSettings();
                },
              )
            ],
          ),
          new TextField(
            decoration: InputDecoration(
                labelText: _authType == "access_token" ? "Access token" : "API password"
            ),
            controller: TextEditingController(
                text: _hassioPassword
            ),
            onChanged: (value) {
              _hassioPassword = value;
              //_saveSettings();
            },
          )
        ],
      ),
    );
  }
}
