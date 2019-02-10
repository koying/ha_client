import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/io.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:date_format/date_format.dart';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:progress_indicators/progress_indicators.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

part 'entity_class/const.dart';
part 'entity_class/entity.class.dart';
part 'entity_class/entity_wrapper.class.dart';
part 'entity_class/switch_entity.class.dart';
part 'entity_class/button_entity.class.dart';
part 'entity_class/text_entity.class.dart';
part 'entity_class/climate_entity.class.dart';
part 'entity_class/cover_entity.class.dart';
part 'entity_class/date_time_entity.class.dart';
part 'entity_class/light_entity.class.dart';
part 'entity_class/select_entity.class.dart';
part 'entity_class/other_entity.class.dart';
part 'entity_class/slider_entity.dart';
part 'entity_class/media_player_entity.class.dart';
part 'entity_class/lock_entity.class.dart';
part 'entity_class/group_entity.class.dart';
part 'entity_class/fan_entity.class.dart';
part 'entity_class/automation_entity.dart';
part 'entity_class/camera_entity.class.dart';
part 'entity_class/alarm_control_panel.class.dart';
part 'entity_widgets/common/badge.dart';
part 'entity_widgets/model_widgets.dart';
part 'entity_widgets/default_entity_container.dart';
part 'entity_widgets/glance_entity_container.dart';
part 'entity_widgets/button_entity_container.dart';
part 'entity_widgets/common/entity_attributes_list.dart';
part 'entity_widgets/entity_icon.dart';
part 'entity_widgets/entity_name.dart';
part 'entity_widgets/common/last_updated.dart';
part 'entity_widgets/common/mode_swicth.dart';
part 'entity_widgets/common/mode_selector.dart';
part 'entity_widgets/common/universal_slider.dart';
part 'entity_widgets/common/flat_service_button.dart';
part 'entity_widgets/common/light_color_picker.dart';
part 'entity_widgets/entity_colors.class.dart';
part 'entity_widgets/entity_page_container.dart';
part 'entity_widgets/history_chart/entity_history.dart';
part 'entity_widgets/history_chart/simple_state_history_chart.dart';
part 'entity_widgets/history_chart/numeric_state_history_chart.dart';
part 'entity_widgets/history_chart/combined_history_chart.dart';
part 'entity_widgets/history_chart/history_control_widget.dart';
part 'entity_widgets/history_chart/entity_history_moment.dart';
part 'entity_widgets/state/switch_state.dart';
part 'entity_widgets/controls/slider_controls.dart';
part 'entity_widgets/state/text_input_state.dart';
part 'entity_widgets/state/select_state.dart';
part 'entity_widgets/state/simple_state.dart';
part 'entity_widgets/state/climate_state.dart';
part 'entity_widgets/state/cover_state.dart';
part 'entity_widgets/state/date_time_state.dart';
part 'entity_widgets/state/lock_state.dart';
part 'entity_widgets/controls/climate_controls.dart';
part 'entity_widgets/controls/cover_controls.dart';
part 'entity_widgets/controls/light_controls.dart';
part 'entity_widgets/controls/media_player_widgets.dart';
part 'entity_widgets/controls/fan_controls.dart';
part 'entity_widgets/controls/alarm_control_panel_controls.dart';
part 'entity_widgets/controls/camera_controls.dart';
part 'settings.page.dart';
part 'home_assistant.class.dart';
part 'log.page.dart';
part 'entity.page.dart';
part 'utils.class.dart';
part 'mdi.class.dart';
part 'entity_collection.class.dart';
part 'ui_class/ui.dart';
part 'ui_class/view.class.dart';
part 'ui_class/card.class.dart';
part 'ui_class/sizes_class.dart';
part 'ui_widgets/view.dart';
part 'ui_widgets/card_widget.dart';
part 'ui_widgets/card_header_widget.dart';


EventBus eventBus = new EventBus();
const String appName = "HA Client";
const appVersion = "0.4.0";
const appBuild = "90";

String homeAssistantWebHost;

void main() {
  FlutterError.onError = (errorDetails) {
    Logger.e( "${errorDetails.exception}");
    if (Logger.isInDebugMode) {
      FlutterError.dumpErrorToConsole(errorDetails);
    }
  };

  runZoned(() {
    runApp(new HAClientApp());
  }, onError: (error, stack) {
    Logger.e("$error");
    Logger.e("$stack");
    if (Logger.isInDebugMode) {
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
        "/": (context) => MainPage(title: 'HA Client'),
        "/connection-settings": (context) => ConnectionSettingsPage(title: "Settings"),
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
  //Map _instanceConfig;
  String _webSocketApiEndpoint;
  String _password;
  //int _uiViewsCount = 0;
  String _instanceHost;
  StreamSubscription _stateSubscription;
  StreamSubscription _settingsSubscription;
  StreamSubscription _serviceCallSubscription;
  StreamSubscription _showEntityPageSubscription;
  StreamSubscription _showErrorSubscription;
  bool _settingsLoaded = false;
  bool _accountMenuExpanded = false;
  bool _useLovelaceUI;

  @override
  void initState() {
    super.initState();
    _settingsLoaded = false;
    WidgetsBinding.instance.addObserver(this);

    Logger.d("<!!!> Creating new HomeAssistant instance");
    _homeAssistant = HomeAssistant();

    _settingsSubscription = eventBus.on<SettingsChangedEvent>().listen((event) {
      Logger.d("Settings change event: reconnect=${event.reconnect}");
      if (event.reconnect) {
        _homeAssistant.disconnect().then((_){
          _initialLoad();
        });
      }
    });
    _initialLoad();
  }

  void _initialLoad() {
    _loadConnectionSettings().then((_){
      _subscribe();
      _refreshData();
    }, onError: (_) {
      _showErrorBottomBar(message: _, errorCode: 5);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Logger.d("$state");
    if (state == AppLifecycleState.resumed && _settingsLoaded) {
      _refreshData();
    }
  }

  _loadConnectionSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String domain = prefs.getString('hassio-domain');
    String port = prefs.getString('hassio-port');
    _instanceHost = "$domain:$port";
    _webSocketApiEndpoint = "${prefs.getString('hassio-protocol')}://$domain:$port/api/websocket";
    homeAssistantWebHost = "${prefs.getString('hassio-res-protocol')}://$domain:$port";
    _password = prefs.getString('hassio-password');
    _useLovelaceUI = prefs.getBool('use-lovelace') ?? true;
    if ((domain == null) || (port == null) || (_password == null) ||
        (domain.length == 0) || (port.length == 0) || (_password.length == 0)) {
      throw("Check connection settings");
    } else {
      _settingsLoaded = true;
    }
  }

  _subscribe() {
    if (_stateSubscription == null) {
      _stateSubscription = eventBus.on<StateChangedEvent>().listen((event) {
        if (event.needToRebuildUI) {
          Logger.d("New entity. Need to rebuild UI");
          _refreshData();
        } else {
          setState(() {});
        }
      });
    }
    if (_serviceCallSubscription == null) {
      _serviceCallSubscription =
          eventBus.on<ServiceCallEvent>().listen((event) {
            _callService(event.domain, event.service, event.entityId,
                event.additionalParams);
          });
    }

    if (_showEntityPageSubscription == null) {
      _showEntityPageSubscription =
          eventBus.on<ShowEntityPageEvent>().listen((event) {
            _showEntityPage(event.entity.entityId);
          });
    }

    if (_showErrorSubscription == null) {
      _showErrorSubscription = eventBus.on<ShowErrorEvent>().listen((event){
        _showErrorBottomBar(message: event.text, errorCode: event.errorCode);
      });
    }
  }

  _refreshData() async {
    _homeAssistant.updateSettings(_webSocketApiEndpoint, _password, _useLovelaceUI);
    _hideBottomBar();
    _showInfoBottomBar(progress: true,);
    await _homeAssistant.fetch().then((result) {
      _hideBottomBar();
    }).catchError((e) {
      _setErrorState(e);
    });
    eventBus.fire(RefreshDataFinishedEvent());
  }

  _setErrorState(e) {
    if (e is Error) {
      Logger.e(e.toString());
      Logger.e("${e.stackTrace}");
      _showErrorBottomBar(
          message: "There was some error",
          errorCode: 13
      );
    } else {
      _showErrorBottomBar(
          message: e != null ? e["errorMessage"] ?? "$e" : "Unknown error",
          errorCode: e["errorCode"] != null ? e["errorCode"] : 99
      );
    }
  }

  void _callService(String domain, String service, String entityId, Map<String, dynamic> additionalParams) {
    _showInfoBottomBar(
      message: "Calling $domain.$service",
      duration: Duration(seconds: 3)
    );
    _homeAssistant.callService(domain, service, entityId, additionalParams).catchError((e) => _setErrorState(e));
  }

  void _showEntityPage(String entityId) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EntityViewPage(entityId: entityId, homeAssistant: _homeAssistant),
        )
    );
  }

  List<Tab> buildUIViewTabs() {
    List<Tab> result = [];

      if (_homeAssistant.ui.views.isNotEmpty) {
        _homeAssistant.ui.views.forEach((HAView view) {
          result.add(view.buildTab());
        });
      }

    return result;
  }

  Drawer _buildAppDrawer() {
    List<Widget> menuItems = [];
    menuItems.add(
        UserAccountsDrawerHeader(
          accountName: Text(_homeAssistant.userName),
          accountEmail: Text(_instanceHost ?? "Not configured"),
          onDetailsPressed: () {
            setState(() {
              _accountMenuExpanded = !_accountMenuExpanded;
            });
          },
          currentAccountPicture: CircleAvatar(
            child: Text(
              _homeAssistant.userAvatarText,
              style: TextStyle(
                  fontSize: 32.0
              ),
            ),
          ),
        )
    );
    if (_accountMenuExpanded) {
      menuItems.addAll([
        ListTile(
          leading: Icon(Icons.settings),
          title: Text("Settings"),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/connection-settings');
          },
        ),
        Divider(),
      ]);
    } else {
      menuItems.addAll([
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
          title: Text("Report an issue"),
          onTap: () {
            Navigator.of(context).pop();
            HAUtils.launchURL("https://github.com/estevez-dev/ha_client/issues/new");
          },
        ),
        Divider(),
        new AboutListTile(
          aboutBoxChildren: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                HAUtils.launchURL("http://ha-client.vynn.co/");
              },
              child: Text(
                "ha-client.vynn.co",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline
                ),
              ),
            )
          ],
          applicationName: appName,
          applicationVersion: appVersion,
          applicationLegalese: "build $appBuild",
        )
      ]);
    }
    return new Drawer(
      child: ListView(
        children: menuItems,
      ),
    );
  }

  void _hideBottomBar() {
    //_scaffoldKey?.currentState?.hideCurrentSnackBar();
    setState(() {
      _showBottomBar = false;
    });
  }

  Widget _bottomBarAction;
  bool _showBottomBar = false;
  String _bottomBarText;
  bool _bottomBarProgress;
  Color _bottomBarColor;
  Timer _bottomBarTimer;

  void _showInfoBottomBar({String message, bool progress: false, Duration duration}) {
    _bottomBarTimer?.cancel();
    _bottomBarAction = Container(height: 0.0, width: 0.0,);
    _bottomBarColor = Colors.grey.shade50;
    setState(() {
      _bottomBarText = message;
      _bottomBarProgress = progress;
      _showBottomBar = true;
    });
    if (duration != null) {
      _bottomBarTimer = Timer(duration, () {
        _hideBottomBar();
      });
    }
  }

  void _showErrorBottomBar({Key key, @required String message, @required int errorCode}) {
    TextStyle textStyle = TextStyle(
      color: Colors.blue,
      fontSize: Sizes.nameFontSize
    );
    _bottomBarColor = Colors.red.shade100;
      switch (errorCode) {
        case 9:
        case 11:
        case 7:
        case 1: {
        _bottomBarAction = FlatButton(
                child: Text("Retry", style: textStyle),
                onPressed: () {
                  //_scaffoldKey?.currentState?.hideCurrentSnackBar();
                  _refreshData();
                },
            );
            break;
          }

        case 5: {
          message = "Check connection settings";
          _bottomBarAction = FlatButton(
              child: Text("Open", style: textStyle),
            onPressed: () {
              //_scaffoldKey?.currentState?.hideCurrentSnackBar();
              Navigator.pushNamed(context, '/connection-settings');
            },
          );
          break;
        }

        case 6: {
          _bottomBarAction = FlatButton(
              child: Text("Settings", style: textStyle),
            onPressed: () {
              //_scaffoldKey?.currentState?.hideCurrentSnackBar();
              Navigator.pushNamed(context, '/connection-settings');
            },
          );
          break;
        }

        case 10: {
          _bottomBarAction = FlatButton(
              child: Text("Refresh", style: textStyle),
            onPressed: () {
              //_scaffoldKey?.currentState?.hideCurrentSnackBar();
              _refreshData();
            },
          );
          break;
        }

        case 8: {
          _bottomBarAction = FlatButton(
              child: Text("Reconnect", style: textStyle),
            onPressed: () {
              //_scaffoldKey?.currentState?.hideCurrentSnackBar();
              _refreshData();
            },
          );
          break;
        }

        default: {
          _bottomBarAction = FlatButton(
              child: Text("Reload", style: textStyle),
            onPressed: () {
              //_scaffoldKey?.currentState?.hideCurrentSnackBar();
              _refreshData();
            },
          );
          break;
        }
      }
      setState(() {
        _bottomBarProgress = false;
        _bottomBarText = "$message (code: $errorCode)";
        _showBottomBar = true;
      });
      /*_scaffoldKey.currentState.hideCurrentSnackBar();
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text("$message (code: $errorCode)"),
          action: action,
          duration: Duration(hours: 1),
        )
      );*/
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Widget _buildScaffoldBody(bool empty) {
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            floating: true,
            pinned: true,
            primary: true,
            title: Text(_homeAssistant != null ? _homeAssistant.locationName : ""),
            actions: <Widget>[
              IconButton(
                icon: Icon(MaterialDesignIcons.createIconDataFromIconName(
                    "mdi:dots-vertical"), color: Colors.white,),
                onPressed: () {
                  showMenu(
                    position: RelativeRect.fromLTRB(MediaQuery.of(context).size.width, 70.0, 0.0, 0.0),
                    context: context,
                    items: [PopupMenuItem<String>(
                      child: new Text("Reload"),
                      value: "reload",
                    )]
                  ).then((String val) {
                    if (val == "reload") {
                      _refreshData();
                    }
                  });
                }
              )
            ],
            leading: IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState.openDrawer();
                setState(() {
                  _accountMenuExpanded = false;
                });
              },
            ),
            bottom: empty ? null : TabBar(
              tabs: buildUIViewTabs(),
              isScrollable: true,
            ),
          ),

        ];
      },
      body: empty ?
      Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                MaterialDesignIcons.createIconDataFromIconName("mdi:home-assistant"),
                size: 100.0,
                color: Colors.blue,
              ),
            ]
        ),
      )
          :
      _homeAssistant.buildViews(context, _useLovelaceUI),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bottomBar;
    if (_showBottomBar) {
      List<Widget> bottomBarChildren = [];
      if (_bottomBarText != null) {
        bottomBarChildren.add(
          Padding(
            padding: EdgeInsets.fromLTRB(
                Sizes.leftWidgetPadding, Sizes.rowPadding, 0.0,
                Sizes.rowPadding),
            child: Text(
              "$_bottomBarText",
              textAlign: TextAlign.left,
              softWrap: true,
            ),
          )

        );
      }
      if (_bottomBarProgress) {
        bottomBarChildren.add(
          CollectionScaleTransition(
            children: <Widget>[
              Icon(Icons.stop, size: 10.0, color: EntityColor.stateColor(EntityState.on),),
              Icon(Icons.stop, size: 10.0, color: EntityColor.stateColor(EntityState.unavailable),),
              Icon(Icons.stop, size: 10.0, color: EntityColor.stateColor(EntityState.off),),
            ],
          ),
        );
      }
      if (bottomBarChildren.isNotEmpty) {
        bottomBar = Container(
          color: _bottomBarColor,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: _bottomBarProgress ? CrossAxisAlignment.center : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: bottomBarChildren,
                ),
              ),
              _bottomBarAction
            ],
          ),
        );
      }
    }
    // This method is rerun every time setState is called.
    if (_homeAssistant.ui == null || _homeAssistant.ui.views == null) {
      return Scaffold(
        key: _scaffoldKey,
        primary: false,
        drawer: _buildAppDrawer(),
        bottomNavigationBar: bottomBar,
        body: _buildScaffoldBody(true)
      );
    } else {
      return Scaffold(
        key: _scaffoldKey,
        drawer: _buildAppDrawer(),
        primary: false,
        bottomNavigationBar: bottomBar,
        body: DefaultTabController(
          length: _homeAssistant.ui?.views?.length ?? 0,
          child: _buildScaffoldBody(false),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_stateSubscription != null) _stateSubscription.cancel();
    if (_settingsSubscription != null) _settingsSubscription.cancel();
    if (_serviceCallSubscription != null) _serviceCallSubscription.cancel();
    if (_showEntityPageSubscription != null) _showEntityPageSubscription.cancel();
    if (_showErrorSubscription != null) _showErrorSubscription.cancel();
    _homeAssistant.disconnect();
    super.dispose();
  }
}
