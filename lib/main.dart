import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as socketStatus;

part 'settings.dart';

void main() => runApp(new HassClientApp());

class HassClientApp extends StatelessWidget {
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
  List _entitiesData = [];
  Map _servicesData = {};
  String _hassioAPIEndpoint = "";
  String _hassioPassword = "";
  IOWebSocketChannel _hassioChannel;
  int _entitiesMessageId = 0;
  int _servicesMessageId = 1;
  int _servicCallMessageId = 2;

  @override
  void initState() {
    super.initState();
    _initClient();
  }

  _initClient() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _hassioAPIEndpoint = "wss://" + prefs.getString('hassio-domain') +":" + prefs.getString('hassio-port') + "/api/websocket";
      _hassioPassword = prefs.getString('hassio-password');
    });
    _connectSocket();
  }

  _connectSocket() async {
    _hassioChannel = await IOWebSocketChannel.connect(_hassioAPIEndpoint);
    _hassioChannel.stream.listen((message) {
      _handleSocketMessage(message);
    });
    debugPrint("Socket connected!");

  }

  _handleSocketMessage(message) {
    debugPrint("<== Message from Home Assistant:");
    debugPrint(message);
    var data = json.decode(message);
    if (data["type"] == "auth_required") {
      _sendHassioAuth();
    } else if (data["type"] == "auth_ok") {
      debugPrint("Auth done!");
      _startDataFetching();
    } else if (data["type"] == "result") {
      if (data["success"] == true) {
        if (data["id"] == _entitiesMessageId) {
          _loadEntities(data["result"]);
          _sendRawMessage('{"id": $_servicesMessageId, "type": "get_services"}');
        } else if (data["id"] == _servicesMessageId) {
          _loadServices(data["result"]);
        }
      } else {
        /*
        Handle error here
         */
      }
    }
  }

  _incrementMessageId() {
    _entitiesMessageId = _servicCallMessageId + 1;
    _servicesMessageId = _entitiesMessageId + 1;
    _servicCallMessageId = _servicesMessageId + 1;
  }

  _sendHassioAuth() {
    _sendRawMessage('{"type": "auth","api_password": "$_hassioPassword"}');
  }

  _startDataFetching() {
    _incrementMessageId();
    _sendRawMessage('{"id": $_entitiesMessageId, "type": "get_states"}');
  }

  _sendRawMessage(message) {
    debugPrint("==> Sending to Home Assistant:");
    debugPrint(message);
    _hassioChannel.sink.add(message);
  }

  _sendServiceCall(String domain, String service, String entityId) {
    _incrementMessageId();
    _sendRawMessage('{"id": $_servicCallMessageId, "type": "call_service", "domain": "$domain", "service": "$service", "service_data": {"entity_id": "$entityId"}}');
  }

  void _loadServices(Map data) {
    setState(() {
      _servicesData = Map.from(data);
    });
  }

  void _loadEntities(List data) {
    Map switchServices = {
      "turn_on": {},
      "turn_off": {},
      "toggle": {}
    };
    debugPrint("Getting Home Assistant entities: ${data.length}");
    data.forEach((entity) {
      var composedEntity = Map.from(entity);
      composedEntity["display_name"] = "${entity["attributes"]!=null ? entity["attributes"]["friendly_name"] ?? entity["attributes"]["name"] : "_"}";
      String entityDomain = entity["entity_id"].split(".")[0];
      composedEntity["domain"] = entityDomain;

      if ((entityDomain == "automation") || (entityDomain == "light") || (entityDomain == "switch") || (entityDomain == "script")) {
        composedEntity["services"] = Map.from(switchServices);
      }

      setState(() {
        _entitiesData.add(composedEntity);
      });
    });
  }

  Widget buildEntityButtons(int i) {
    if (_entitiesData[i]["services"] == null || _entitiesData[i]["services"].length == 0) {
      return new Container(width: 0.0, height: 0.0);
    }
    List<Widget> buttons = [];
    _entitiesData[i]["services"].forEach((key, value) {
      buttons.add(new FlatButton(
        child: Text(_entitiesData[i]["domain"] + ".$key"),
        onPressed: () {
          _sendServiceCall(_entitiesData[i]["domain"], key, _entitiesData[i]["entity_id"]);
        },
      ));
    });
    return ButtonBar(
      children: buttons
    );
  }

  Widget buildEntityCard(int i) {
    return Card(
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new ListTile(
            leading: const Icon(Icons.device_hub),
            subtitle: Text("${_entitiesData[i]["entity_id"]}"),
            trailing: Text("${_entitiesData[i]["state"]}"),
            title: Text("${_entitiesData[i]["display_name"]}"),
          ),
          new ButtonTheme.bar( // make buttons use the appropriate styles for cards
            child: buildEntityButtons(i),
          ),
        ],
      ),
    );



    return Padding(
        padding: EdgeInsets.all(10.0),
        child: Text("Row ${_entitiesData[i]["entity_id"]}")
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
          itemCount: _entitiesData.length,
          itemBuilder: (BuildContext context, int position) {
            return buildEntityCard(position);
          }),
      floatingActionButton: new FloatingActionButton(
        onPressed: _startDataFetching,
        tooltip: 'Increment',
        child: new Icon(Icons.refresh),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  void dispose() {
    _hassioChannel.sink.close();
    super.dispose();
  }
}
