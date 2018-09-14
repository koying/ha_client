import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as socketStatus;
import 'package:progress_indicators/progress_indicators.dart';

part 'settings.dart';
part 'data_model.dart';

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

  final String title;

  @override
  _MainPageState createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage> {

  HassioDataModel _dataModel;
  Map _entitiesData;
  String _dataModelErrorMessage = "";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _initClient();
  }

  _initClient() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _hassioAPIEndpoint = "wss://" + prefs.getString('hassio-domain') +":" + prefs.getString('hassio-port') + "/api/websocket";
    String _hassioPassword = prefs.getString('hassio-password');
    _dataModel = HassioDataModel(_hassioAPIEndpoint, _hassioPassword);
    await _refreshData();
  }

  _refreshData() async {
    setState(() {
      loading = true;
    });
    _dataModelErrorMessage = "";
    if (_dataModel != null) {
      await _dataModel.fetch().then((result) {
        setState(() {
          _entitiesData = _dataModel._uiStructure;
          loading = false;
        });
      }).catchError((e) {
        setState(() {
          _dataModelErrorMessage = e.toString();
          loading = false;
        });
      });
    }
  }

  Widget buildEntityButtons(String entityId) {
    if (_entitiesData[entityId]["services"] == null || _entitiesData[entityId]["services"].length == 0) {
      return new Container(width: 0.0, height: 0.0);
    }
    List<Widget> buttons = [];
    _entitiesData[entityId]["services"].forEach((key, value) {
      buttons.add(new FlatButton(
        child: Text('$key'),
        onPressed: () {
          _dataModel.callService(_entitiesData[entityId]["domain"], key, _entitiesData[entityId]["entity_id"]);
        },
      ));
    });
    return ButtonBar(
      children: buttons
    );
  }

  Widget buildEntityCard(data) {
    return Card(
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new ListTile(
            leading: const Icon(Icons.device_hub),
            subtitle: Text("${data['entity_id']}"),
            trailing: Text("${data["state"]}"),
            title: Text("${data["display_name"]}"),
          ),
          new ButtonTheme.bar( // make buttons use the appropriate styles for cards
            child: buildEntityButtons(data['entity_id']),
          ),
        ],
      ),
    );
  }

  List<Widget> buildEntitiesView() {
    if (_entitiesData != null) {
      List<Widget> result = [];
      if (_dataModelErrorMessage.length == 0) {
        _entitiesData.forEach((key, data) {
          if (data != null) {
            result.add(buildEntityCard(data));
          } else {
            debugPrint("Unknown entity: $key");
          }
        });
      } else {
        result.add(Text(_dataModelErrorMessage));
      }
      return result;
    } else {
      return [Container(width: 0.0, height: 0.0)];
    }
  }

  Widget _buildTitle() {
    Row titleRow = Row(
      children: <Widget>[
        Text(widget.title)
      ],
    );
    if (loading) {
      titleRow.children.add(Padding(
        child: JumpingDotsProgressIndicator(
          fontSize: 30.0,
          color: Colors.white,
        ),
        padding: const EdgeInsets.fromLTRB(5.0, 0.0, 0.0, 40.0),
        )
      );
    }
    return titleRow;
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
        title: _buildTitle(),
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
      body: ListView(
        children: buildEntitiesView(),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _refreshData,
        tooltip: 'Increment',
        child: new Icon(Icons.refresh),
      ),
    );
  }

  @override
  void dispose() {
    //TODO
    //_hassioChannel.sink.close();
    super.dispose();
  }
}
