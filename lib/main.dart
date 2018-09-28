import 'dart:convert';
import 'dart:async';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

part 'settings.page.dart';
part 'home_assistant.class.dart';
part 'log.page.dart';
part 'utils.class.dart';
part 'mdi.class.dart';
part 'entity.class.dart';
part 'entity_collection.class.dart';
part 'ui_builder_class.dart';
part 'view_class.dart';
part 'card_class.dart';
part 'badge_class.dart';

EventBus eventBus = new EventBus();
const String appName = "HA Client";
const appVersion = "0.1.3";

String homeAssistantWebHost;

void main() {
  FlutterError.onError = (errorDetails) {
    TheLogger.log("Error", "${errorDetails.exception}");
    if (TheLogger.isInDebugMode) {
      FlutterError.dumpErrorToConsole(errorDetails);
    }
  };

  runZoned(() {
    runApp(new HAClientApp());
  }, onError: (error, stack) {
    TheLogger.log("Global error", "$error");
    if (TheLogger.isInDebugMode) {
      debugPrint("$stack");
    }
  });
}

class HAClientApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: appName,
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => MainPage(title: 'Hass Client'),
        "/connection-settings": (context) => ConnectionSettingsPage(title: "Connection Settings"),
        "/log-view": (context) => LogViewPage(title: "Log")
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

class _MainPageState extends State<MainPage> with WidgetsBindingObserver {
  HomeAssistant _homeAssistant;
  EntityCollection _entities;
  //Map _instanceConfig;
  int _uiViewsCount = 0;
  String _instanceHost;
  int _errorCodeToBeShown = 0;
  String _lastErrorMessage = "";
  StreamSubscription _stateSubscription;
  StreamSubscription _settingsSubscription;
  bool _isLoading = true;
  Map<String, Color> _stateIconColors = {
    "on": Colors.amber,
    "off": Color.fromRGBO(68, 115, 158, 1.0),
    "unavailable": Colors.black12,
    "unknown": Colors.black12,
    "playing": Colors.amber
  };
  Map<String, Color> _badgeColors = {
    "default": Color.fromRGBO(223, 76, 30, 1.0),
    "binary_sensor": Color.fromRGBO(3, 155, 229, 1.0)
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settingsSubscription = eventBus.on<SettingsChangedEvent>().listen((event) {
      TheLogger.log("Debug","Settings change event: reconnect=${event.reconnect}");
      setState(() {
        _errorCodeToBeShown = 0;
      });
      _initConnection();
    });
    _initConnection();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    TheLogger.log("Debug","$state");
    if (state == AppLifecycleState.resumed) {
      _refreshData();
    }
  }

  _initConnection() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String domain = prefs.getString('hassio-domain');
    String port = prefs.getString('hassio-port');
    _instanceHost = "$domain:$port";
    String apiEndpoint = "${prefs.getString('hassio-protocol')}://$domain:$port/api/websocket";
    homeAssistantWebHost = "${prefs.getString('hassio-res-protocol')}://$domain:$port";
    String apiPassword = prefs.getString('hassio-password');
    String authType = prefs.getString('hassio-auth-type');
    if ((domain == null) || (port == null) || (apiPassword == null) ||
        (domain.length == 0) || (port.length == 0) || (apiPassword.length == 0)) {
      setState(() {
        _errorCodeToBeShown = 5;
      });
    } else {
      if (_homeAssistant != null) _homeAssistant.closeConnection();
      _createConnection(apiEndpoint, apiPassword, authType);
    }
  }

  _createConnection(String apiEndpoint, String apiPassword, String authType) {
    _homeAssistant = HomeAssistant(apiEndpoint, apiPassword, authType);
    _refreshData();
    if (_stateSubscription != null) _stateSubscription.cancel();
    _stateSubscription = eventBus.on<StateChangedEvent>().listen((event) {
      setState(() {
        _entities = _homeAssistant.entities;
      });
    });
  }

  _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    _errorCodeToBeShown = 0;
    if (_homeAssistant != null) {
      await _homeAssistant.fetch().then((result) {
        setState(() {
          //_instanceConfig = _homeAssistant.instanceConfig;
          _entities = _homeAssistant.entities;
          _uiViewsCount = _homeAssistant.viewsCount;
          _isLoading = false;
        });
      }).catchError((e) {
        _setErrorState(e);
      });
    }
  }

  _setErrorState(e) {
    setState(() {
      _errorCodeToBeShown = e["errorCode"] != null ? e["errorCode"] : 99;
      _lastErrorMessage = e["errorMessage"] ?? "Unknown error";
      _isLoading = false;
    });
  }

  void _callService(String domain, String service, String entityId) {
    setState(() {
      _isLoading = true;
    });
    _homeAssistant.callService(domain, service, entityId).then((r) {
      setState(() {
        _isLoading = false;
      });
    }).catchError((e) => _setErrorState(e));
  }

  List<Widget> _buildViews() {
    List<Widget> result = [];
    if ((_entities != null) && (!_homeAssistant.uiBuilder.isEmpty)) {
      _homeAssistant.uiBuilder.views.forEach((viewId, view) {
        result.add(
            RefreshIndicator(
              color: Colors.amber,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: _buildSingleView(view),
              ),
              onRefresh: () => _refreshData(),
            )
        );
      });
    }
    return result;
  }

  List<Widget> _buildSingleView(View view) {
    List<Widget> result = [];
    if (view.isThereBadges) {
      result.add(
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 10.0,
          runSpacing: 1.0,
          children: _buildBadges(view.badges),
        )
      );

    }
    view.cards.forEach((id, card) {
      if (card.entities.isNotEmpty) {
        result.add(_buildCard(card));
      }
    });

    return result;
  }

  List<Widget> _buildBadges( Map<String, Badge> badges) {
    List<Widget> result = [];
    badges.forEach((id, badge) {
      var badgeEntity = _entities.get(id);
      if (badgeEntity != null) {
        result.add(
          _buildSingleBadge(badgeEntity)
        );
      }
    });
    return result;
  }

  Widget _buildSingleBadge(Entity data) {
    double iconSize = 26.0;
    Widget badgeIcon;
    String badgeTextValue;
    Color iconColor = _badgeColors[data.domain] ?? _badgeColors["default"];
    switch (data.domain) {
      case "sun": {
        badgeIcon = data.state == "below_horizon" ?
          Icon(
            MaterialDesignIcons.createIconDataFromIconCode(0xf0dc),
            size: iconSize,
          ) :
          Icon(
            MaterialDesignIcons.createIconDataFromIconCode(0xf5a8),
            size: iconSize,
          );
        break;
      }
      case "sensor": {
        badgeTextValue = data.unitOfMeasurement;
        badgeIcon = Center(
          child: Text(
            "${data.state == 'unknown' ? '-' : data.state}",
            overflow: TextOverflow.fade,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17.0),
          ),
        );
        break;
      }
      case "device_tracker": {
        badgeIcon = MaterialDesignIcons.createIconWidgetFromEntityData(data, iconSize,Colors.black);
        badgeTextValue = data.state;
        break;
      }
      default: {
       badgeIcon = MaterialDesignIcons.createIconWidgetFromEntityData(data, iconSize,Colors.black);
      }
    }
    Widget badgeText;
    if (badgeTextValue == null || badgeTextValue.length == 0) {
      badgeText = Container(width: 0.0, height: 0.0);
    } else {
      badgeText = Container(
          padding: EdgeInsets.fromLTRB(6.0, 2.0, 6.0, 2.0),
          child: Text("$badgeTextValue",
              style: TextStyle(fontSize: 12.0, color: Colors.white),
              textAlign: TextAlign.center, softWrap: false, overflow: TextOverflow.fade),
          decoration: new BoxDecoration(
            // Circle shape
            //shape: BoxShape.circle,
            color: iconColor,
            borderRadius: BorderRadius.circular(9.0),
          )
      );
    }
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
          width: 50.0,
          height: 50.0,
          decoration: new BoxDecoration(
            // Circle shape
            shape: BoxShape.circle,
            color: Colors.white,
            // The border you want
            border: new Border.all(
              width: 2.0,
              color: iconColor,
            ),
          ),
          child: Stack(
            overflow: Overflow.visible,
            children: <Widget>[
              Positioned(
                width: 46.0,
                height: 46.0,
                top: 0.0,
                left: 0.0,
                child: badgeIcon,
              ),
              Positioned(
                //width: 50.0,
                bottom: -9.0,
                left: -10.0,
                right: -10.0,
                child: Center(
                  child: badgeText,
                )
              )
            ],
          ),
        ),
        Container(
          width: 60.0,
          child: Text(
            "${data.displayName}",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.0),
            softWrap: true,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Card _buildCard(HACard card) {
    List<Widget> body = [];
    body.add(_buildCardHeader(card.friendlyName));
    body.addAll(_buildCardBody(card.entities));
    Card result = Card(
        child: new Column(mainAxisSize: MainAxisSize.min, children: body)
    );
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

  List<Widget> _buildCardBody(List ids) {
    List<Widget> entities = [];
    ids.forEach((id) {
      var data = _entities.get(id);
      if (data != null) {
        entities.add(new ListTile(
          leading: MaterialDesignIcons.createIconWidgetFromEntityData(data, 28.0, _stateIconColors[data.state] ?? Colors.blueGrey),
          //subtitle: Text("${data['entity_id']}"),
          trailing: _buildEntityActionWidget(data),
          title: Text(
            "${data.displayName}",
            overflow: TextOverflow.fade,
            softWrap: false,
          ),
        ));
      }
    });
    return entities;
  }

  Widget _buildEntityActionWidget(Entity entity) {
    String entityId = entity.entityId;
    Widget result;
    switch (entity.domain) {
      case "automation":
      case "switch":
      case "light": {
        result = Switch(
          value: entity.isOn,
          onChanged: ((state) {
            _callService(
                entity.domain, state ? "turn_on" : "turn_off", entityId
            );
            //TODO remove after checking if state will chenge without setState but after socket event
            /*setState(() {
              _entities[entityId]["state"] = state ? "on" : "off";
            });*/
          }),
        );
        break;
      }

      case "script":
      case "scene": {
        result = SizedBox(
          width: 60.0,
          child: FlatButton(
            onPressed: (() {
              _callService(entity.domain, "turn_on", entityId);
            }),
            child: Text(
              "Run",
              textAlign: TextAlign.right,
              style: new TextStyle(fontSize: 16.0, color: Colors.blue),
            ),
          )
        );
        break;
      }

      default: {
        result = Padding(
          padding: EdgeInsets.fromLTRB(0.0, 0.0, 16.0, 0.0),
          child: Text(
            "${entity.state}${entity.unitOfMeasurement}",
            textAlign: TextAlign.right,
            style: new TextStyle(
              fontSize: 16.0,
            )
          )
        );
      }
    }

    /*return SizedBox(
      width: 60.0,
      // height: double.infinity,
      child: result
    );*/
    return result;
  }

  List<Tab> buildUIViewTabs() {
    List<Tab> result = [];
    if ((_entities != null) && (!_homeAssistant.uiBuilder.isEmpty)) {
      _homeAssistant.uiBuilder.views.forEach((viewId, view) {
        result.add(
            Tab(
                icon: MaterialDesignIcons.createIconWidgetFromEntityData(_entities.get(viewId), 24.0, null) ??
                    Icon(
                      MaterialDesignIcons.createIconDataFromIconName("mdi:home-assistant"),
                      size: 24.0,
                    )
            )
        );
      });
    }
    return result;
  }

  Widget _buildAppTitle() {
    Row titleRow = Row(
      children: [Text(_homeAssistant != null ? _homeAssistant.locationName : "")],
    );
    if (_isLoading) {
      titleRow.children.add(Padding(
        child: JumpingDotsProgressIndicator(
          fontSize: 26.0,
          color: Colors.white,
        ),
        padding: const EdgeInsets.fromLTRB(5.0, 0.0, 0.0, 30.0),
      ));
    }
    return titleRow;
  }

  Drawer _buildAppDrawer() {
    return new Drawer(
      child: ListView(
        children: <Widget>[
          new UserAccountsDrawerHeader(
            accountName: Text(_homeAssistant != null ? _homeAssistant.locationName : "Unknown"),
            accountEmail: Text(_instanceHost ?? "Not configured"),
            currentAccountPicture: new Image.asset('images/hassio-192x192.png'),
          ),
          new ListTile(
            leading: Icon(Icons.settings),
            title: Text("Connection settings"),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/connection-settings');
            },
          ),
          new ListTile(
            leading: Icon(Icons.insert_drive_file),
            title: Text("Log"),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/log-view');
            },
          ),
          new ListTile(
            leading: Icon(MaterialDesignIcons.createIconDataFromIconName("mdi:github-circle")),
            title: Text("Reprot issue"),
            onTap: () {
              Navigator.of(context).pop();
              haUtils.launchURL("https://github.com/estevez-dev/ha_client_pub/issues/new");
            },
          ),
          new AboutListTile(
            applicationName: appName,
            applicationVersion: appVersion,
            applicationLegalese: "Keyboard Crumbs | www.keyboardcrumbs.io",
          )
        ],
      ),
    );
  }

  _checkShowInfo(BuildContext context) {
    if (_errorCodeToBeShown > 0) {
      String message = _lastErrorMessage;
      SnackBarAction action;
      switch (_errorCodeToBeShown) {
        case 1: {
            action = SnackBarAction(
                label: "Retry",
                onPressed: () {
                  _scaffoldKey?.currentState?.hideCurrentSnackBar();
                  _refreshData();
                },
            );
            break;
          }

        case 5: {
          message = "Check connection settings";
          action = SnackBarAction(
            label: "Open",
            onPressed: () {
              _scaffoldKey?.currentState?.hideCurrentSnackBar();
              Navigator.pushNamed(context, '/connection-settings');
            },
          );
          break;
        }

        case 6: {
          action = SnackBarAction(
            label: "Settings",
            onPressed: () {
              _scaffoldKey?.currentState?.hideCurrentSnackBar();
              Navigator.pushNamed(context, '/connection-settings');
            },
          );
          break;
        }

        case 7: {
          action = SnackBarAction(
            label: "Retry",
            onPressed: () {
              _scaffoldKey?.currentState?.hideCurrentSnackBar();
              _refreshData();
            },
          );
          break;
        }

        case 8: {
          action = SnackBarAction(
            label: "Reconnect",
            onPressed: () {
              _scaffoldKey?.currentState?.hideCurrentSnackBar();
              _refreshData();
            },
          );
          break;
        }
      }
      Timer(Duration(seconds: 1), () {
        _scaffoldKey.currentState.hideCurrentSnackBar();
        _scaffoldKey.currentState.showSnackBar(
            SnackBar(
                content: Text("$message (code: $_errorCodeToBeShown)"),
                action: action,
                duration: Duration(hours: 1),
            )
        );
      });
    } else {
      _scaffoldKey?.currentState?.hideCurrentSnackBar();
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Scaffold _buildScaffold(bool empty) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _buildAppTitle(),
        bottom: empty ? null : TabBar(tabs: buildUIViewTabs()),
      ),
      drawer: _buildAppDrawer(),
      body: empty ?
        Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  MaterialDesignIcons.createIconDataFromIconName("mdi:home-assistant"),
                  size: 100.0,
                  color: _errorCodeToBeShown == 0 ? Colors.blue : Colors.redAccent,
                ),
              ]
          ),
        )
        :
        TabBarView(
            children: _buildViews()
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _checkShowInfo(context);
    // This method is rerun every time setState is called.
    if (_entities == null) {
      return _buildScaffold(true);
    } else {
      return DefaultTabController(
          length: _uiViewsCount,
          child: _buildScaffold(false)
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_stateSubscription != null) _stateSubscription.cancel();
    if (_settingsSubscription != null) _settingsSubscription.cancel();
    _homeAssistant.closeConnection();
    super.dispose();
  }
}
