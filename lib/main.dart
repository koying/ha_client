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
  List _composedEntitiesData = [];
  String _hassioAPIEndpoint = "";
  String _hassioPassword = "";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hassioAPIEndpoint = "https://" + prefs.getString('hassio-domain') +":" + prefs.getString('hassio-port') + "/api/";
      _hassioPassword = prefs.getString('hassio-password');
    });
  }

  void _loadHassioData() async {
    await _loadSettings();
    http.Response entitiesResponse = await http.get(_hassioAPIEndpoint + "states", headers: {"X-HA-Access": _hassioPassword, "Content-Type": "application/json"});
    http.Response servicesResponse = await http.get(_hassioAPIEndpoint + "services", headers: {"X-HA-Access": _hassioPassword, "Content-Type": "application/json"});
    http.Response configResponse = await http.get(_hassioAPIEndpoint + "config", headers: {"X-HA-Access": _hassioPassword, "Content-Type": "application/json"});
    List _entities = json.decode(entitiesResponse.body);
    List _services = json.decode(servicesResponse.body);
    Map _config = json.decode(configResponse.body);
    List result = [];
    _entities.forEach((entity) {
      var composedEntity = Map();
      composedEntity["entity_id"] = entity["entity_id"];
      composedEntity["display_name"] = "${entity["attributes"]!=null ? entity["attributes"]["friendly_name"] ?? entity["attributes"]["name"] : "_"}";
      composedEntity["state"] = entity["state"];
      composedEntity["last_changed"] = entity["last_changed"];
      String entityDomain = entity["entity_id"].split(".")[0];
      composedEntity["domain"] = entityDomain;

      _services.forEach((service) {
        if (service["domain"] == entityDomain) {
          composedEntity["services"] = new Map.from(service["services"]);
        }
      });

      result.add(composedEntity);
    });
    setState(() {
      _composedEntitiesData = result;
    });
  }

  Widget buildEntityButtons(int i) {
    if (_composedEntitiesData[i]["services"] == null || _composedEntitiesData[i]["services"].length == 0) {
      return new Container(width: 0.0, height: 0.0);
    }
    List<Widget> buttons = [];
    _composedEntitiesData[i]["services"].forEach((key, value) {
      buttons.add(new FlatButton(
        child: Text(_composedEntitiesData[i]["domain"] + ".$key"),
        onPressed: () {/*......*/},
      ));
    });
    return ButtonBar(
      children: buttons
    );
  }

  Widget parseEntity(int i) {
    return Card(
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new ListTile(
            leading: const Icon(Icons.device_hub),
            subtitle: Text("${_composedEntitiesData[i]["entity_id"]}"),
            trailing: Text("${_composedEntitiesData[i]["state"]}"),
            title: Text("${_composedEntitiesData[i]["display_name"]}"),
          ),
          new ButtonTheme.bar( // make buttons use the appropriate styles for cards
            child: buildEntityButtons(i),
          ),
        ],
      ),
    );



    return Padding(
        padding: EdgeInsets.all(10.0),
        child: Text("Row ${_composedEntitiesData[i]["entity_id"]}")
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
          itemCount: _composedEntitiesData.length,
          itemBuilder: (BuildContext context, int position) {
            return parseEntity(position);
          }),
      floatingActionButton: new FloatingActionButton(
        onPressed: _loadHassioData,
        tooltip: 'Increment',
        child: new Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
