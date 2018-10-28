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
import 'package:date_format/date_format.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_colorpicker/material_picker.dart';
import 'package:charts_flutter/flutter.dart' as charts;

part 'entity_class/entity.class.dart';
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
part 'entity_widgets/badge.dart';
part 'entity_widgets/model_widgets.dart';
part 'entity_widgets/default_entity_container.dart';
part 'entity_widgets/entity_attributes_list.dart';
part 'entity_widgets/entity_icon.dart';
part 'entity_widgets/entity_name.dart';
part 'entity_widgets/last_updated.dart';
part 'entity_widgets/mode_swicth.dart';
part 'entity_widgets/mode_selector.dart';
part 'entity_widgets/entity_page_container.dart';
part 'entity_widgets/history_chart/entity_history.dart';
part 'entity_widgets/history_chart/simple_state_history_chart.dart';
part 'entity_widgets/history_chart/numeric_state_history_chart.dart';
part 'entity_widgets/state/switch_state.dart';
part 'entity_widgets/state/slider_state.dart';
part 'entity_widgets/state/text_input_state.dart';
part 'entity_widgets/state/select_state.dart';
part 'entity_widgets/state/simple_state.dart';
part 'entity_widgets/state/climate_state.dart';
part 'entity_widgets/state/cover_state.dart';
part 'entity_widgets/state/date_time_state.dart';
part 'entity_widgets/state/button_state.dart';
part 'entity_widgets/controls/climate_controls.dart';
part 'entity_widgets/controls/cover_controls.dart';
part 'entity_widgets/controls/light_controls.dart';
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
part 'ui_widgets/view.dart';
part 'ui_widgets/entities_card.dart';
part 'ui_widgets/unsupported_card.dart';
part 'ui_widgets/media_control_card.dart';

EventBus eventBus = new EventBus();
const String appName = "HA Client";
const appVersion = "0.3.3.48";

String homeAssistantWebHost;

void main() {
  FlutterError.onError = (errorDetails) {
    TheLogger.error( "${errorDetails.exception}");
    if (TheLogger.isInDebugMode) {
      FlutterError.dumpErrorToConsole(errorDetails);
    }
  };

  runZoned(() {
    runApp(new HAClientApp());
  }, onError: (error, stack) {
    TheLogger.error("$error");
    TheLogger.error("$stack");
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
  EntityCollection _entities;
  //Map _instanceConfig;
  String _webSocketApiEndpoint;
  String _password;
  String _authType;
  //int _uiViewsCount = 0;
  String _instanceHost;
  StreamSubscription _stateSubscription;
  StreamSubscription _settingsSubscription;
  StreamSubscription _serviceCallSubscription;
  StreamSubscription _showEntityPageSubscription;
  StreamSubscription _refreshDataSubscription;
  StreamSubscription _showErrorSubscription;
  int _isLoading = 1;
  bool _settingsLoaded = false;
  bool _accountMenuExpanded = false;
  bool _useLovelaceUI;

  @override
  void initState() {
    super.initState();
    _settingsLoaded = false;
    WidgetsBinding.instance.addObserver(this);

    _homeAssistant = HomeAssistant();

    _settingsSubscription = eventBus.on<SettingsChangedEvent>().listen((event) {
      TheLogger.debug("Settings change event: reconnect=${event.reconnect}");
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
      setState(() {
        _isLoading = 2;
      });
      _showErrorSnackBar(message: _, errorCode: 5);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    TheLogger.debug("$state");
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
    _authType = prefs.getString('hassio-auth-type');
    _useLovelaceUI = prefs.getBool('use-lovelace') ?? false;
    if ((domain == null) || (port == null) || (_password == null) ||
        (domain.length == 0) || (port.length == 0) || (_password.length == 0)) {
      throw("Check connection settings");
    } else {
      _settingsLoaded = true;
    }
  }

  _subscribe() {
    if (_stateSubscription == null) {
      //TODO Move to homeAssistant or remove
      _stateSubscription = eventBus.on<StateChangedEvent>().listen((event) {
        setState(() {
          if (event.localChange) {
            _entities
                .get(event.entityId)
                .state = event.newState;
          }
        });
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
            _showEntityPage(event.entity);
          });
    }

    if (_refreshDataSubscription == null) {
      _refreshDataSubscription = eventBus.on<RefreshDataEvent>().listen((event){
        _refreshData();
      });
    }

    if (_showErrorSubscription == null) {
      _showErrorSubscription = eventBus.on<ShowErrorEvent>().listen((event){
        _showErrorSnackBar(message: event.text, errorCode: event.errorCode);
      });
    }
  }

  _refreshData() async {
    _homeAssistant.updateSettings(_webSocketApiEndpoint, _password, _authType, _useLovelaceUI);
    setState(() {
      _hideErrorSnackBar();
      _isLoading = 1;
    });
    await _homeAssistant.fetch().then((result) {
      setState(() {
        //_instanceConfig = _homeAssistant.instanceConfig;
        _entities = _homeAssistant.entities;
        //_uiViewsCount = _homeAssistant.viewsCount;
        //TheLogger.debug("_uiViewsCount=$_uiViewsCount");
        _isLoading = 0;
      });
    }).catchError((e) {
      _setErrorState(e);
    });
    eventBus.fire(RefreshDataFinishedEvent());
  }

  _setErrorState(e) {
    setState(() {
      _isLoading = 2;
    });
    _showErrorSnackBar(
        message: e != null ? e["errorMessage"] ?? "$e" : "Unknown error",
        errorCode: e["errorCode"] != null ? e["errorCode"] : 99
    );
  }

  void _callService(String domain, String service, String entityId, Map<String, dynamic> additionalParams) {
    _homeAssistant.callService(domain, service, entityId, additionalParams).catchError((e) => _setErrorState(e));
  }

  void _showEntityPage(Entity entity) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EntityViewPage(entity: entity, homeAssistant: _homeAssistant),
        )
    );
  }

  List<Tab> buildUIViewTabs() {
    List<Tab> result = [];

      if (_homeAssistant.ui.views.isNotEmpty) {
        _homeAssistant.ui.views.forEach((HAView view) {
          if (view.linkedEntity == null) {
            result.add(
                Tab(
                    icon:
                    Icon(
                      MaterialDesignIcons.createIconDataFromIconName(
                          view.iconName ?? "mdi:home-assistant"),
                      size: 24.0,
                    )
                )
            );
          } else {
            result.add(
                Tab(
                    icon: MaterialDesignIcons.createIconWidgetFromEntityData(
                        view.linkedEntity, 24.0, null) ??
                        Icon(
                          MaterialDesignIcons.createIconDataFromIconName(
                              "mdi:home-assistant"),
                          size: 24.0,
                        )
                )
            );
          }
        });
      }

    return result;
  }

  Widget _buildAppTitle() {
    Row titleRow = Row(
      children: [Text(_homeAssistant != null ? _homeAssistant.locationName : "")],
    );
    if (_isLoading == 1) {
      titleRow.children.add(Padding(
        child: JumpingDotsProgressIndicator(
          fontSize: 26.0,
          color: Colors.white,
        ),
        padding: const EdgeInsets.fromLTRB(5.0, 0.0, 0.0, 30.0),
      ));
    } else if (_isLoading == 2) {
      titleRow.children.add(Padding(
        child: Icon(
            Icons.error_outline,
            size: 20.0,
          color: Colors.red,
        ),
        padding: const EdgeInsets.fromLTRB(5.0, 0.0, 0.0, 0.0),
      ));
    }
    return titleRow;
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
            HAUtils.launchURL("https://github.com/estevez-dev/ha_client_pub/issues/new");
          },
        ),
        Divider(),
        new AboutListTile(
          applicationName: appName,
          applicationVersion: appVersion,
          applicationLegalese: "Keyboard Crumbs | www.keyboardcrumbs.io",
        )
      ]);
    }
    return new Drawer(
      child: ListView(
        children: menuItems,
      ),
    );
  }

  void _hideErrorSnackBar() {
    _scaffoldKey?.currentState?.hideCurrentSnackBar();
  }

  void _showErrorSnackBar({Key key, @required String message, @required int errorCode}) {
      SnackBarAction action;
      switch (errorCode) {
        case 9:
        case 11:
        case 7:
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

        case 10: {
          action = SnackBarAction(
            label: "Refresh",
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
      _scaffoldKey.currentState.hideCurrentSnackBar();
      _scaffoldKey.currentState.showSnackBar(
        SnackBar(
          content: Text("$message (code: $errorCode)"),
          action: action,
          duration: Duration(hours: 1),
        )
      );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Scaffold _buildScaffold(bool empty) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: _buildAppTitle(),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState.openDrawer();
            setState(() {
              _accountMenuExpanded = false;
            });
          },
        ),
        primary: true,
        bottom: empty ? null : TabBar(
            tabs: buildUIViewTabs(),
            isScrollable: true,
        ),
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
                  color: _isLoading == 2 ? Colors.redAccent : Colors.blue,
                ),
              ]
          ),
        )
        :
        _homeAssistant.buildViews(context, _useLovelaceUI)
    );
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    if (_homeAssistant.entities.isEmpty) {
      return _buildScaffold(true);
    } else {
      return DefaultTabController(
          length: _homeAssistant.ui.views.length,
          child: _buildScaffold(false)
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
    if (_refreshDataSubscription != null) _refreshDataSubscription.cancel();
    if (_showErrorSubscription != null) _showErrorSubscription.cancel();
    _homeAssistant.disconnect();
    super.dispose();
  }
}
