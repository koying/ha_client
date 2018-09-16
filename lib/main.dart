import 'dart:convert';
import 'dart:async';
import 'package:flutter/rendering.dart';
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
  Map _uiStructure;
  int _uiViewsCount = 0;
  String _dataModelErrorMessage = "";
  bool loading = true;
  Map _stateIconColors = {
    "on": Colors.amber,
    "off": Colors.blueGrey,
    "unavailable": Colors.black12,
    "unknown": Colors.black12,
    "playing": Colors.amber
  };

  @override
  void initState() {
    super.initState();
    _initClient();
  }

  _initClient() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String _hassioAPIEndpoint = "wss://" +
        prefs.getString('hassio-domain') +
        ":" +
        prefs.getString('hassio-port') +
        "/api/websocket";
    String _hassioPassword = prefs.getString('hassio-password');
    _dataModel = HassioDataModel(_hassioAPIEndpoint, _hassioPassword);
    await _refreshData();
  }

  _refreshData() async {
    setState(() {
      loading = true;
    });
    _dataModelErrorMessage = null;
    if (_dataModel != null) {
      await _dataModel.fetch().then((result) {
        setState(() {
          _entitiesData = _dataModel.entities;
          _uiStructure = _dataModel.uiStructure;
          _uiViewsCount = _uiStructure.length;
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

  Widget _buildEntityAction(String entityId) {
    var entity = _entitiesData[entityId];
    Widget result;
    if (entity["actionType"] == "switch") {
      result = Switch(
        value: (entity["state"] == "on"),
        onChanged: ((state) {
          _dataModel.callService(
              entity["domain"], state ? "turn_on" : "turn_off", entityId);
          setState(() {
            _entitiesData[entityId]["state"] = state ? "on" : "off";
          });
        }),
      );
    } else if (entity["actionType"] == "statelessIcon") {
      result = SizedBox(
          width: 60.0,
          child: FlatButton(
            onPressed: (() {
              _dataModel.callService(entity["domain"], "turn_on", entityId);
            }),
            child: Text(
              "Run",
              textAlign: TextAlign.right,
              style: new TextStyle(fontSize: 16.0, color: Colors.blue),
            ),
          ));
    } else {
      result = Padding(
          padding: EdgeInsets.fromLTRB(0.0, 0.0, 16.0, 0.0),
          child: Text(
              "${entity["state"]}${(entity["attributes"] != null && entity["attributes"]["unit_of_measurement"] != null) ? entity["attributes"]["unit_of_measurement"] : ''}",
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: 16.0,
              )));
    }
    /*return SizedBox(
      width: 60.0,
      // height: double.infinity,
      child: result
    );*/
    return result;
  }

  Card _buildCard(List<String> ids, String name) {
    List<Widget> body = [];
    body.add(_buildCardHeader(name));
    body.addAll(_buildCardBody(ids));
    Card result =
        Card(child: new Column(mainAxisSize: MainAxisSize.min, children: body));
    return result;
  }

  Widget _buildCardHeader(String name) {
    var result;
    if (name.length > 0) {
      result = new ListTile(
        //leading: const Icon(Icons.device_hub),
        //subtitle: Text(".."),
        //trailing: Text("${data["state"]}"),
        title: Text("$name",
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            style: new TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0)),
      );
    } else {
      result = new Container(width: 0.0, height: 0.0);
    }
    return result;
  }

  List<Widget> _buildCardBody(List<String> ids) {
    List<Widget> entities = [];
    ids.forEach((id) {
      var data = _entitiesData[id];
      entities.add(new ListTile(
        leading: Icon(
          _createMDIfromCode(data["iconCode"]),
          color: _stateIconColors[data["state"]] ?? Colors.blueGrey,
        ),
        //subtitle: Text("${data['entity_id']}"),
        trailing: _buildEntityAction(id),
        title: Text(
          "${data["display_name"]}",
          overflow: TextOverflow.ellipsis,
        ),
      ));
    });
    return entities;
  }

  List<Widget> buildSingleView(structure) {
      List<Widget> result = [];
      structure["standalone"].forEach((entityId) {
        result.add(_buildCard([entityId], ""));
      });
      structure["groups"].forEach((group) {
        result.add(_buildCard(
            group["children"], group["friendly_name"].toString()));
      });

      return result;
  }

  List<ListView> buildUIViews() {
    List<ListView> result = [];
    if ((_entitiesData != null) && (_uiStructure != null)) {
      _uiStructure.forEach((viewId, structure) {
        result.add(ListView(
          children: buildSingleView(structure),
        ));
      });
    }
    return result;
  }

  IconData _createMDIfromCode(int code) {
    return IconData(code, fontFamily: 'Material Design Icons');
  }

  List<Tab> buildUIViewTabs() {
    List<Tab> result = [];
    if ((_entitiesData != null) && (_uiStructure != null)) {
      _uiStructure.forEach((viewId, structure) {
        result.add(
            Tab(icon: Icon(_createMDIfromCode(structure["iconCode"])))
        );
      });
    }
    return result;
  }

  Widget _buildTitle() {
    Row titleRow = Row(
      children: <Widget>[Text(widget.title)],
    );
    if (loading) {
      titleRow.children.add(Padding(
        child: JumpingDotsProgressIndicator(
          fontSize: 30.0,
          color: Colors.white,
        ),
        padding: const EdgeInsets.fromLTRB(5.0, 0.0, 0.0, 40.0),
      ));
    }
    return titleRow;
  }

  Drawer _buildAppDrawer() {
    return new Drawer(
      child: ListView(
        children: <Widget>[
          new UserAccountsDrawerHeader(
            accountName: Text("Edwin Home"),
            accountEmail: Text("edwin-home.duckdns.org"),
            currentAccountPicture: new CircleAvatar(
              backgroundImage: new NetworkImage(
                  "https://edwin-home.duckdns.org:8123/static/icons/favicon-192x192.png"),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    //
    if (_entitiesData == null) {
      return new Scaffold(
        appBar: new AppBar(
          title: _buildTitle()
        ),
        drawer: _buildAppDrawer(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 10.0),
                child: Text(
                    _dataModelErrorMessage != null ? "Well... no.\n\nThere was an error: $_dataModelErrorMessage\n\nCheck your internet connection or something" : "Loading... or not...\n\nJust wait 10 seconds",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16.0),
                ),
              ),
              GlowingProgressIndicator(
                child: Icon(
                    _createMDIfromCode(MaterialDesignIcons.getCustomIconByName("mdi:home-assistant")),
                    size: 40.0,
                ),
              ),
            ]
          ),
        ),
        //Text(_dataModelErrorMessage != null ? "Well... no.\n\nThere was an error:\n$_dataModelErrorMessage" : "Loading... or not...\n\nJust wait 10 seconds"),
        floatingActionButton: new FloatingActionButton(
          onPressed: _refreshData,
          tooltip: 'Increment',
          child: new Icon(Icons.refresh),
        ),
      );
    } else {
      return DefaultTabController(
          length: _uiViewsCount,
          child: new Scaffold(
            appBar: new AppBar(
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              title: _buildTitle(),
              bottom: TabBar(
                  tabs: buildUIViewTabs()
              ),
            ),
            drawer: _buildAppDrawer(),
            body: TabBarView(
                children: buildUIViews()
            ),
            floatingActionButton: new FloatingActionButton(
              onPressed: _refreshData,
              tooltip: 'Increment',
              child: new Icon(Icons.refresh),
            ),
          )
      );
    }
  }

  @override
  void dispose() {
    //TODO
    //_hassioChannel.sink.close();
    super.dispose();
  }
}
