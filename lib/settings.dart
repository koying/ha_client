part of 'main.dart';

class ConnectionSettingsPage extends StatefulWidget {
  ConnectionSettingsPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _ConnectionSettingsPageState createState() => new _ConnectionSettingsPageState();
}

class _ConnectionSettingsPageState extends State<ConnectionSettingsPage> {
  String _hassioDomain = "";
  String _hassioPort = "8123";
  String _hassioPassword = "";
  String _socketProtocol = "wss";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _hassioDomain = prefs.getString("hassio-domain");
      _hassioPort = prefs.getString("hassio-port") ?? '8123';
      _hassioPassword = prefs.getString("hassio-password");
      _socketProtocol = prefs.getString("hassio-protocol") ?? 'wss';
    });
  }

  _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("hassio-domain", _hassioDomain);
    prefs.setString("hassio-port", _hassioPort);
    prefs.setString("hassio-password", _hassioPassword);
    prefs.setString("hassio-protocol", _socketProtocol);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
          _saveSettings().then((r){
            Navigator.pop(context);
          });
          eventBus.fire(SettingsChangedEvent(true));
        }),
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
          new Row(
            children: [
              Text("HTTPS"),
              Switch(
                value: (_socketProtocol == "wss"),
                onChanged: (value) {
                  setState(() {
                    _socketProtocol = value ? "wss" : "ws";
                  });
                  _saveSettings();
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
              _saveSettings();
            },
          ),
          new TextField(
            decoration: InputDecoration(
              labelText: "Home Assistant port"
            ),
            controller: TextEditingController(
              text: _hassioPort
            ),
            onChanged: (value) {
              _hassioPort = value;
              _saveSettings();
            },
          ),
          new TextField(
            decoration: InputDecoration(
                labelText: "Home Assistant password"
            ),
            controller: TextEditingController(
                text: _hassioPassword
            ),
            onChanged: (value) {
              _hassioPassword = value;
              _saveSettings();
            },
          )
        ],
      ),
    );
  }
}