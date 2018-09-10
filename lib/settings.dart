part of 'main.dart';

class SettingsPage extends StatefulWidget {
  SettingsPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _SettingsPageState createState() => new _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _hassioDomain = "";
  String _hassioPort = "";
  String _hassioPassword = "";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _hassioDomain = prefs.getString("hassio-domain");
      _hassioPort = prefs.getString("hassio-port");
      _hassioPassword = prefs.getString("hassio-password");
    });
  }

  _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      prefs.setString("hassio-domain", _hassioDomain);
      prefs.setString("hassio-port", _hassioPort);
      prefs.setString("hassio-password", _hassioPassword);
      _hassioPassword = prefs.getString('hassio-password');
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
      appBar: new AppBar(
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){
          _saveSettings();
          Navigator.pop(context);
        }),
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: <Widget>[
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
              labelText: "Home Assistant port"
            ),
            controller: TextEditingController(
              text: _hassioPort
            ),
            onChanged: (value) {
              _hassioPort = value;
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
            },
          )
        ],
      ),
    );
  }
}