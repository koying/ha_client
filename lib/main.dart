import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Hass Client',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => MainPage(title: 'Hass Client'),
        "/settings": (context) => SettingsPage(title: "Settings")
      },
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MainPageState createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List _entities = [];
  String _hassioUrl = "";
  String _hassioPassword = "";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hassioUrl = "https://" + prefs.getString('hassio-domain') +":" + prefs.getString('hassio-port') + "/api/states";
      _hassioPassword = prefs.getString('hassio-password');
    });
  }

  void _getHassioEntities() async {
    await _loadSettings();
    http.Response response = await http.get(_hassioUrl, headers: {"X-HA-Access": _hassioPassword});
    setState(() {
      _entities = json.decode(response.body);
    });
  }

  Widget parseEntity(int i) {
    return Card(
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new ListTile(
            leading: const Icon(Icons.device_hub),
            title: Text("${_entities[i]["entity_id"]}"),
            subtitle: Text("${_entities[i]["state"]}"),
          ),
        ],
      ),
    );



    return Padding(
        padding: EdgeInsets.all(10.0),
        child: Text("Row ${_entities[i]["entity_id"]}")
    );
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
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      drawer: new Drawer(
        child: ListView(
          children: <Widget>[
            new UserAccountsDrawerHeader(
                accountName: Text("Edwin Home"),
                accountEmail: Text("edwin-home.duckdns.org"),
                currentAccountPicture: new CircleAvatar(
                  backgroundImage: new NetworkImage("https://edwin-home.duckdns.org:8123/static/icons/favicon-192x192.png"),
                ),
            ),
            new ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
              onTap: () {
                Navigator.pushNamed(context, '/settings');
              },
            ),
            new AboutListTile(
              applicationName: "Hass Client",
              applicationVersion: "0.1",
              applicationLegalese: "Keyboard Crumbs",
            )
          ],
        ),
      ),
      body: ListView.builder(
          itemCount: _entities.length,
          itemBuilder: (BuildContext context, int position) {
            return parseEntity(position);
          }),
      floatingActionButton: new FloatingActionButton(
        onPressed: _getHassioEntities,
        tooltip: 'Increment',
        child: new Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
