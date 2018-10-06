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
  bool _edited = false;
  FocusNode _domainFocusNode;
  FocusNode _portFocusNode;
  FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    _domainFocusNode = FocusNode();
    _portFocusNode = FocusNode();
    _passwordFocusNode = FocusNode();
    _domainFocusNode.addListener(_checkConfigChanged);
    _portFocusNode.addListener(_checkConfigChanged);
    _passwordFocusNode.addListener(_checkConfigChanged);
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
    });
  }

  void _checkConfigChanged() {
    setState(() {
      _edited = ((_newHassioPassword != _hassioPassword) ||
          (_newHassioPort != _hassioPort) ||
          (_newHassioDomain != _hassioDomain) ||
          (_newSocketProtocol != _socketProtocol) ||
          (_newAuthType != _authType));
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
                value: (_newSocketProtocol == "wss"),
                onChanged: (value) {
                  _newSocketProtocol = value ? "wss" : "ws";
                  _checkConfigChanged();
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
            },
            focusNode: _domainFocusNode,
            onEditingComplete: _checkConfigChanged,
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
              //_saveSettings();
            },
            focusNode: _portFocusNode,
            onEditingComplete: _checkConfigChanged,
          ),
          new Row(
            children: [
              Text("Login with access token (HA >= 0.78.0)"),
              Switch(
                value: (_newAuthType == "access_token"),
                onChanged: (value) {
                  _newAuthType = value ? "access_token" : "api_password";
                  _checkConfigChanged();
                  //_saveSettings();
                },
              )
            ],
          ),
          new TextField(
            decoration: InputDecoration(
                labelText: _authType == "access_token" ? "Access token" : "API password"
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
              //_saveSettings();
            },
            focusNode: _passwordFocusNode,
            onEditingComplete: _checkConfigChanged,
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _domainFocusNode.removeListener(_checkConfigChanged);
    _portFocusNode.removeListener(_checkConfigChanged);
    _passwordFocusNode.removeListener(_checkConfigChanged);
    _domainFocusNode.dispose();
    _portFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }
}
