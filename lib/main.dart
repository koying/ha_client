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
import 'package:device_info/device_info.dart';

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
part 'device.class.dart';
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
final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
const String appName = "HA Client";
const appVersion = "0.6.0-alpha2";

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
  StreamSubscription _showDialogSubscription;
  StreamSubscription _reloadUISubscription;
  int _previousViewCount;
  bool _showLoginButton = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    );

    _settingsSubscription = eventBus.on<SettingsChangedEvent>().listen((event) {
      Logger.d("Settings change event: reconnect=${event.reconnect}");
      if (event.reconnect) {
        _fullLoad();
      }
    });

    _fullLoad();
  }

  void _fullLoad() async {
    _showInfoBottomBar(progress: true,);
    _subscribe().then((_) {
      Connection().init(loadSettings: true, forceReconnect: true).then((__){
        _fetchData();
      }, onError: (e) {
        _setErrorState(e);
      });
    });
  }

  void _quickLoad() {
    _hideBottomBar();
    _showInfoBottomBar(progress: true,);
    Connection().init(loadSettings: false, forceReconnect: false).then((_){
      _fetchData();
    }, onError: (e) {
      _setErrorState(e);
    });
  }

  _fetchData() async {
    await widget.homeAssistant.fetchData().then((_) {
      _hideBottomBar();
      int currentViewCount = widget.homeAssistant.ui?.views?.length ?? 0;
      if (_previousViewCount != currentViewCount) {
        Logger.d("Views count changed ($_previousViewCount->$currentViewCount). Creating new tabs controller.");
        _viewsTabController = TabController(vsync: this, length: currentViewCount);
        _previousViewCount = currentViewCount;
      }
    }).catchError((e) {
      if (e is HAError) {
        _setErrorState(e);
      } else {
        _setErrorState(HAError(e.toString()));
      }
    });
    eventBus.fire(RefreshDataFinishedEvent());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    Logger.d("$state");
    if (state == AppLifecycleState.resumed && Connection().settingsLoaded) {
      _quickLoad();
    }
  }

  Future _subscribe() {
    Completer completer = Completer();
    if (_stateSubscription == null) {
      _stateSubscription = eventBus.on<StateChangedEvent>().listen((event) {
        if (event.needToRebuildUI) {
          Logger.d("New entity. Need to rebuild UI");
          _quickLoad();
        } else {
          setState(() {});
        }
      });
    }
    if (_reloadUISubscription == null) {
      _reloadUISubscription = eventBus.on<ReloadUIEvent>().listen((event){
        _quickLoad();
      });
    }
    if (_showDialogSubscription == null) {
      _showDialogSubscription = eventBus.on<ShowDialogEvent>().listen((event){
        _showDialog(
          title: event.title,
          body: event.body,
          onPositive: event.onPositive,
          onNegative: event.onNegative,
          positiveText: event.positiveText,
          negativeText: event.negativeText
        );
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
        _showErrorBottomBar(event.error);
      });
    }

    if (_startAuthSubscription == null) {
      _startAuthSubscription = eventBus.on<StartAuthEvent>().listen((event){
        setState(() {
          _showLoginButton = event.showButton;
        });
      });
    }

    _firebaseMessaging.getToken().then((String token) {
      HomeAssistant().fcmToken = token;
      completer.complete();
    });
    //completer.complete();
    return completer.future;
  }

  void _showOAuth() {
    Logger.d("_showOAuth: ${Connection().oauthUrl}");
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebviewScaffold(
            url: "${Connection().oauthUrl}",
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

  _setErrorState(HAError e) {
    if (e == null) {
      _showErrorBottomBar(
        HAError("Unknown error")
      );
    } else {
      _showErrorBottomBar(e);
    }
  }

  void _showDialog({String title, String body, var onPositive, var onNegative, String positiveText, String negativeText}) {
    // flutter defined function
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: new Text("$title"),
          content: new Text("$body"),
          actions: <Widget>[
            // usually buttons at the bottom of the dialog
            new FlatButton(
              child: new Text("$positiveText"),
              onPressed: () {
                Navigator.of(context).pop();
                if (onPositive != null) {
                  onPositive();
                }
              },
            ),
            new FlatButton(
              child: new Text("$negativeText"),
              onPressed: () {
                Navigator.of(context).pop();
                if (onNegative != null) {
                  onNegative();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _callService(String domain, String service, String entityId, Map additionalParams) {
    _showInfoBottomBar(
      message: "Calling $domain.$service",
      duration: Duration(seconds: 3)
    );
    Connection().callService(domain: domain, service: service, entityId: entityId, additionalServiceData: additionalParams).catchError((e) => _setErrorState(e));
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
          accountEmail: Text(Connection().displayHostname ?? "Not configured"),
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
                    onTap: () {
                      Navigator.of(context).pop();
                      panel.handleOpen(context);
                    }
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
            onTap: () => HAUtils.launchURL(Connection().httpWebHost),
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
            ),
            Container(
              height: 10.0,
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                HAUtils.launchURLInCustomTab(context, "http://ha-client.homemade.systems/terms_and_conditions");
              },
              child: Text(
                "Terms and Conditions",
                style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline
                ),
              ),
            ),
            Container(
              height: 10.0,
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                HAUtils.launchURLInCustomTab(context, "http://ha-client.homemade.systems/privacy_policy");
              },
              child: Text(
                "Privacy Policy",
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

  void _showErrorBottomBar(HAError error) {
    TextStyle textStyle = TextStyle(
        color: Colors.blue,
        fontSize: Sizes.nameFontSize
    );
    _bottomBarColor = Colors.red.shade100;
    List<Widget> actions = [];
    error.actions.forEach((HAErrorAction action) {
      switch (action.type) {
        case HAErrorActionType.FULL_RELOAD: {
          actions.add(FlatButton(
            child: Text("${action.title}", style: textStyle),
            onPressed: () {
              _fullLoad();
            },
          ));
          break;
        }

        case HAErrorActionType.QUICK_RELOAD: {
          actions.add(FlatButton(
            child: Text("${action.title}", style: textStyle),
            onPressed: () {
              _quickLoad();
            },
          ));
          break;
        }

        case HAErrorActionType.URL: {
          actions.add(FlatButton(
            child: Text("${action.title}", style: textStyle),
            onPressed: () {
              HAUtils.launchURLInCustomTab(context, "${action.url}");
            },
          ));
          break;
        }

        case HAErrorActionType.OPEN_CONNECTION_SETTINGS: {
          actions.add(FlatButton(
            child: Text("${action.title}", style: textStyle),
            onPressed: () {
              Navigator.pushNamed(context, '/connection-settings');
            },
          ));
          break;
        }
      }
    });
    if (actions.isNotEmpty) {
      _bottomBarAction = Row(
        mainAxisSize: MainAxisSize.min,
        children: actions,
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      _bottomBarAction = Container(height: 0.0, width: 0.0,);
    }
    setState(() {
      _bottomBarProgress = false;
      _bottomBarText = "${error.message}";
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
    List<Widget> emptyBody = [
      Text("."),
    ];
    if (Connection().isAuthenticated) {
      _showLoginButton = false;
      popupMenuItems.add(
          PopupMenuItem<String>(
            child: new Text("Logout"),
            value: "logout",
          ));
    }
    if (_showLoginButton) {
      emptyBody = [
        FlatButton(
          child: Text("Login with Home Assistant", style: TextStyle(fontSize: 16.0, color: Colors.white)),
          color: Colors.blue,
          onPressed: () => _showOAuth(),
        )
      ];
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
                      _quickLoad();
                    } else if (val == "logout") {
                      widget.homeAssistant.logout().then((_) {
                        _quickLoad();
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
            children: emptyBody
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
        body: _buildScaffoldBody(false),
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
