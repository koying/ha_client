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
import 'package:url_launcher/url_launcher.dart' as urlLauncher;
import 'package:flutter/services.dart';
import 'package:date_format/date_format.dart';
import 'package:http/http.dart' as http;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:progress_indicators/progress_indicators.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'entity_class/const.dart';
part 'entity_class/entity.class.dart';
part 'entity_class/entity_wrapper.class.dart';
part 'entity_class/timer_entity.dart';
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
part 'entity_widgets/missed_entity.dart';
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
part 'entity_widgets/common/camera_stream_view.dart';
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
part 'entity_widgets/state/timer_state.dart';
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
part 'settings.page.dart';
part 'panel.page.dart';
part 'home_assistant.class.dart';
part 'log.page.dart';
part 'entity.page.dart';
part 'utils.class.dart';
part 'mdi.class.dart';
part 'entity_collection.class.dart';
part 'auth_manager.class.dart';
part 'connection.class.dart';
part 'ui_class/ui.dart';
part 'ui_class/view.class.dart';
part 'ui_class/card.class.dart';
part 'ui_class/sizes_class.dart';
part 'ui_class/panel_class.dart';
part 'ui_widgets/view.dart';
part 'ui_widgets/card_widget.dart';
part 'ui_widgets/card_header_widget.dart';
part 'ui_widgets/config_panel_widget.dart';


EventBus eventBus = new EventBus();
const String appName = "HA Client";
const appVersion = "0.5.2";

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

  final HomeAssistant homeAssistant = HomeAssistant();
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
        "/": (context) => MainPage(title: 'HA Client', homeAssistant: homeAssistant,),
        "/connection-settings": (context) => ConnectionSettingsPage(title: "Settings"),
        "/configuration": (context) => PanelPage(title: "Configuration"),
        "/log-view": (context) => LogViewPage(title: "Log")
      },
    );
  }
}

class MainPage extends StatefulWidget {
  MainPage({Key key, this.title, this.homeAssistant}) : super(key: key);

  final String title;
  final HomeAssistant homeAssistant;

  @override
  _MainPageState createState() => new _MainPageState();
}

class _MainPageState extends State<MainPage> with WidgetsBindingObserver, TickerProviderStateMixin {

  StreamSubscription _stateSubscription;
  StreamSubscription _settingsSubscription;
  StreamSubscription _serviceCallSubscription;
  StreamSubscription _showEntityPageSubscription;
  StreamSubscription _showErrorSubscription;
  StreamSubscription _startAuthSubscription;
  StreamSubscription _reloadUISubscription;
  int _previousViewCount;
  //final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  void initState() {
    super.initState();
    //widget.homeAssistant = HomeAssistant();
    //_settingsLoaded = false;
    WidgetsBinding.instance.addObserver(this);

    _settingsSubscription = eventBus.on<SettingsChangedEvent>().listen((event) {
      Logger.d("Settings change event: reconnect=${event.reconnect}");
      if (event.reconnect) {
        _reLoad();
      }
    });

    _initialLoad();
  }

  void _initialLoad() {
    _showInfoBottomBar(progress: true,);
    _subscribe();
    widget.homeAssistant.init().then((_){
      _fetchData();
    }, onError: (e) {
      _setErrorState(e);
    });
  }

  void _reLoad() {
    _hideBottomBar();
    _showInfoBottomBar(progress: true,);
    widget.homeAssistant.init().then((_){
      _fetchData();
    }, onError: (e) {
      _setErrorState(e);
    });
  }

  _fetchData() async {
    await widget.homeAssistant.fetch().then((_) {
      _hideBottomBar();
      int currentViewCount = widget.homeAssistant.ui?.views?.length ?? 0;
      if (_previousViewCount != currentViewCount) {
        Logger.d("Views count changed ($_previousViewCount->$currentViewCount). Creating new tabs controller.");
        _viewsTabController = TabController(vsync: this, length: currentViewCount);
        _previousViewCount = currentViewCount;
      }
    }).catchError((e) {
      _setErrorState(e);
    });
    eventBus.fire(RefreshDataFinishedEvent());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Logger.d("$state");
    if (state == AppLifecycleState.resumed) {
      _reLoad();
    }
  }

  _subscribe() {
    if (_stateSubscription == null) {
      _stateSubscription = eventBus.on<StateChangedEvent>().listen((event) {
        if (event.needToRebuildUI) {
          Logger.d("New entity. Need to rebuild UI");
          _reLoad();
        } else {
          setState(() {});
        }
      });
    }
    if (_reloadUISubscription == null) {
      _reloadUISubscription = eventBus.on<ReloadUIEvent>().listen((event){
        _reLoad();
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

    if (_startAuthSubscription == null) {
      _startAuthSubscription = eventBus.on<StartAuthEvent>().listen((event){
        _showOAuth();
      });
    }



    /*_firebaseMessaging.getToken().then((String token) {
      //Logger.d("FCM token: $token");
      widget.homeAssistant.sendHTTPPost(
          endPoint: '/api/notify.fcm-android',
          jsonData:  '{"token": "$token"}'
      );
    });
    _firebaseMessaging.configure(
        onLaunch: (data) {
          Logger.d("Notification [onLaunch]: $data");
        },
        onMessage: (data) {
          Logger.d("Notification [onMessage]: $data");
        },
        onResume: (data) {
          Logger.d("Notification [onResume]: $data");
        }
    );*/
  }

  void _showOAuth() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebviewScaffold(
            url: "${widget.homeAssistant.connection.oauthUrl}",
            appBar: new AppBar(
              leading: IconButton(
                  icon: Icon(Icons.help),
                  onPressed: () => HAUtils.launchURLInCustomTab(context, "http://ha-client.homemade.systems/docs#authentication")
              ),
              title: new Text("Login to your Home Assistant"),
            ),
          ),
        )
    );
  }

  _setErrorState(e) {
    if (e is Error) {
      Logger.e(e.toString());
      Logger.e("${e.stackTrace}");
      _showErrorBottomBar(
          message: "Unknown error",
          errorCode: 13
      );
    } else {
      _showErrorBottomBar(
          message: e != null ? e["errorMessage"] ?? "$e" : "Unknown error",
          errorCode: e["errorCode"] != null ? e["errorCode"] : 99
      );
    }
  }

  void _callService(String domain, String service, String entityId, Map additionalParams) {
    _showInfoBottomBar(
      message: "Calling $domain.$service",
      duration: Duration(seconds: 3)
    );
    widget.homeAssistant.connection.callService(domain: domain, service: service, entityId: entityId, additionalServiceData: additionalParams).catchError((e) => _setErrorState(e));
  }

  void _showEntityPage(String entityId) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EntityViewPage(entityId: entityId, homeAssistant: widget.homeAssistant),
        )
    );
  }

  List<Tab> buildUIViewTabs() {
    List<Tab> result = [];

      if (widget.homeAssistant.ui.views.isNotEmpty) {
        widget.homeAssistant.ui.views.forEach((HAView view) {
          result.add(view.buildTab());
        });
      }

    return result;
  }

  Drawer _buildAppDrawer() {
    List<Widget> menuItems = [];
    menuItems.add(
        UserAccountsDrawerHeader(
          accountName: Text(widget.homeAssistant.userName),
          accountEmail: Text(widget.homeAssistant.hostname ?? "Not configured"),
          /*onDetailsPressed: () {
            setState(() {
              _accountMenuExpanded = !_accountMenuExpanded;
            });
          },*/
          currentAccountPicture: CircleAvatar(
            child: Text(
              widget.homeAssistant.userAvatarText,
              style: TextStyle(
                  fontSize: 32.0
              ),
            ),
          ),
        )
    );
      if (widget.homeAssistant.panels.isNotEmpty) {
        widget.homeAssistant.panels.forEach((Panel panel) {
          if (!panel.isHidden) {
            menuItems.add(
                new ListTile(
                    leading: Icon(MaterialDesignIcons.getIconDataFromIconName(panel.icon)),
                    title: Text("${panel.title}"),
                    onTap: () => panel.handleOpen(context)
                )
            );
          }
        });
      }
      //TODO check for loaded
      menuItems.add(
          new ListTile(
            leading: Icon(MaterialDesignIcons.getIconDataFromIconName("mdi:home-assistant")),
            title: Text("Open Web UI"),
            onTap: () => HAUtils.launchURL(widget.homeAssistant.connection.httpWebHost),
          )
      );
      menuItems.addAll([
        Divider(),
        ListTile(
          leading: Icon(MaterialDesignIcons.getIconDataFromIconName("mdi:login-variant")),
          title: Text("Connection settings"),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/connection-settings', arguments: {"homeAssistant", widget.homeAssistant});
          },
        )
      ]);
      menuItems.addAll([
        Divider(),
        new ListTile(
          leading: Icon(Icons.insert_drive_file),
          title: Text("Log"),
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/log-view');
          },
        ),
        new ListTile(
          leading: Icon(MaterialDesignIcons.getIconDataFromIconName("mdi:github-circle")),
          title: Text("Report an issue"),
          onTap: () {
            Navigator.of(context).pop();
            HAUtils.launchURL("https://github.com/estevez-dev/ha_client/issues/new");
          },
        ),
        Divider(),
        new ListTile(
          leading: Icon(MaterialDesignIcons.getIconDataFromIconName("mdi:discord")),
          title: Text("Join Discord server"),
          onTap: () {
            Navigator.of(context).pop();
            HAUtils.launchURL("https://discord.gg/AUzEvwn");
          },
        ),
        new AboutListTile(
          aboutBoxChildren: <Widget>[
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                HAUtils.launchURL("http://ha-client.homemade.systems/");
              },
              child: Text(
                "ha-client.homemade.systems",
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline
                ),
              ),
            )
          ],
          applicationName: appName,
          applicationVersion: appVersion
        )
      ]);
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
                  _reLoad();
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

        case 60: {
          _bottomBarAction = FlatButton(
              child: Text("Login", style: textStyle),
            onPressed: () {
              _reLoad();
            },
          );
          break;
        }

        case 63:
        case 61: {
          _bottomBarAction = FlatButton(
            child: Text("Try again", style: textStyle),
            onPressed: () {
              _reLoad();
            },
          );
          break;
        }

        case 62: {
          _bottomBarAction = FlatButton(
            child: Text("Login again", style: textStyle),
            onPressed: () {
              _reLoad();
            },
          );
          break;
        }

        case 10: {
          _bottomBarAction = FlatButton(
              child: Text("Refresh", style: textStyle),
            onPressed: () {
              //_scaffoldKey?.currentState?.hideCurrentSnackBar();
              _reLoad();
            },
          );
          break;
        }

        case 82:
        case 81:
        case 8: {
          _bottomBarAction = FlatButton(
              child: Text("Reconnect", style: textStyle),
            onPressed: () {
              _reLoad();
            },
          );
          break;
        }

        default: {
          _bottomBarAction = Container(width: 0.0, height: 0.0,);
          break;
        }
      }
      setState(() {
        _bottomBarProgress = false;
        _bottomBarText = "$message";
        _showBottomBar = true;
      });
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Widget _buildScaffoldBody(bool empty) {
    List<PopupMenuItem<String>> popupMenuItems = [];
    popupMenuItems.add(PopupMenuItem<String>(
      child: new Text("Reload"),
      value: "reload",
    ));
    if (widget.homeAssistant.connection.isAuthenticated) {
      popupMenuItems.add(
          PopupMenuItem<String>(
            child: new Text("Logout"),
            value: "logout",
          ));
    }
    return NestedScrollView(
      headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
        return <Widget>[
          SliverAppBar(
            floating: true,
            pinned: true,
            primary: true,
            title: Text(widget.homeAssistant.locationName ?? ""),
            actions: <Widget>[
              IconButton(
                icon: Icon(MaterialDesignIcons.getIconDataFromIconName(
                    "mdi:dots-vertical"), color: Colors.white,),
                onPressed: () {
                  showMenu(
                    position: RelativeRect.fromLTRB(MediaQuery.of(context).size.width, 70.0, 0.0, 0.0),
                    context: context,
                    items: popupMenuItems
                  ).then((String val) {
                    if (val == "reload") {
                      _reLoad();
                    } else if (val == "logout") {
                      widget.homeAssistant.logout().then((_) {
                        _reLoad();
                      });
                    }
                  });
                }
              )
            ],
            leading: IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState.openDrawer();
              },
            ),
            bottom: empty ? null : TabBar(
              controller: _viewsTabController,
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
                MaterialDesignIcons.getIconDataFromIconName("mdi:border-none-variant"),
                size: 100.0,
                color: Colors.black26,
              ),
            ]
        ),
      )
          :
      widget.homeAssistant.buildViews(context, _viewsTabController),
    );
  }

  TabController _viewsTabController;

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
    if (widget.homeAssistant.isNoViews) {
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
        body: HomeAssistantModel(
          child: _buildScaffoldBody(false),
          homeAssistant: widget.homeAssistant
        ),
      );
    }
  }

  @override
  void dispose() {
    final flutterWebviewPlugin = new FlutterWebviewPlugin();
    flutterWebviewPlugin.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _viewsTabController?.dispose();
    _stateSubscription?.cancel();
    _settingsSubscription?.cancel();
    _serviceCallSubscription?.cancel();
    _showEntityPageSubscription?.cancel();
    _showErrorSubscription?.cancel();
    _startAuthSubscription?.cancel();
    _reloadUISubscription?.cancel();
    //TODO disconnect
    //widget.homeAssistant?.disconnect();
    super.dispose();
  }
}
