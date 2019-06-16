part of 'main.dart';

class HomeAssistant {

  static final HomeAssistant _instance = HomeAssistant._internal();

  factory HomeAssistant() {
    return _instance;
  }

  EntityCollection entities;
  HomeAssistantUI ui;
  Map _instanceConfig = {};
  String _userName;
  HSVColor savedColor;

  String fcmToken;

  Map _rawLovelaceData;

  List<Panel> panels = [];

  Duration fetchTimeout = Duration(seconds: 30);

  String get locationName {
    if (Connection().useLovelace) {
      return ui?.title ?? "";
    } else {
      return _instanceConfig["location_name"] ?? "";
    }
  }
  String get userName => _userName ?? locationName;
  String get userAvatarText => userName.length > 0 ? userName[0] : "";
  bool get isNoEntities => entities == null || entities.isEmpty;
  bool get isNoViews => ui == null || ui.isEmpty;
  bool get isMobileAppEnabled => _instanceConfig["components"] != null && (_instanceConfig["components"] as List).contains("mobile_app");

  HomeAssistant._internal() {
    Connection().onStateChangeCallback = _handleEntityStateChange;
    Device().loadDeviceInfo();
  }

  Completer _fetchCompleter;

  Future fetchData() {
    if (_fetchCompleter != null && !_fetchCompleter.isCompleted) {
      Logger.w("Previous data fetch is not completed yet");
      return _fetchCompleter.future;
    }
    if (entities == null) entities = EntityCollection(Connection().httpWebHost);
    _fetchCompleter = Completer();
    List<Future> futures = [];
    futures.add(_getStates());
    if (Connection().useLovelace) {
      futures.add(_getLovelace());
    }
    futures.add(_getConfig());
    futures.add(_getServices());
    futures.add(_getUserInfo());
    futures.add(_getPanels());
    futures.add(Connection().sendSocketMessage(
      type: "subscribe_events",
      additionalData: {"event_type": "state_changed"},
    ));
    Future.wait(futures).then((_) {
      if (isMobileAppEnabled) {
        _createUI();
        _fetchCompleter.complete();
        checkAppRegistration();
      } else {
        _fetchCompleter.completeError(HAError("Mobile app component not found", actions: [HAErrorAction.tryAgain(), HAErrorAction(type: HAErrorActionType.URL ,title: "Help",url: "http://ha-client.homemade.systems/docs#mobile-app")]));
      }
    }).catchError((e) {
      _fetchCompleter.completeError(e);
    });
    return _fetchCompleter.future;
  }

  Future logout() async {
    Logger.d("Logging out...");
    await Connection().logout().then((_) {
      ui?.clear();
      entities?.clear();
      panels?.clear();
    });
  }

  Map _getAppRegistrationData() {
    return {
      "app_version": "$appVersion",
      "device_name": "$userName's ${Device().model}",
      "manufacturer": Device().manufacturer,
      "model": Device().model,
      "os_name": Device().osName,
      "os_version": Device().osVersion,
      "app_data": {
        "push_token": "$fcmToken",
        "push_url": "https://us-central1-ha-client-c73c4.cloudfunctions.net/sendPushNotification"
      }
    };
  }

  Future checkAppRegistration({bool forceRegister: false, bool forceUpdate: false}) {
    Completer completer = Completer();
    if (Connection().webhookId == null || forceRegister) {
      Logger.d("Mobile app was not registered yet or need to be reseted. Registering...");
      var registrationData = _getAppRegistrationData();
      registrationData.addAll({
        "app_id": "ha_client",
        "app_name": "$appName",
        "supports_encryption": false,
      });
      Connection().sendHTTPPost(
              endPoint: "/api/mobile_app/registrations",
              includeAuthHeader: true,
              data: json.encode(registrationData)
          ).then((response) {
            Logger.d("Processing registration responce...");
            var responseObject = json.decode(response);
            SharedPreferences.getInstance().then((prefs) {
              prefs.setString("app-webhook-id", responseObject["webhook_id"]);
              Connection().webhookId = responseObject["webhook_id"];
              prefs.setString("registered-app-version", "$appVersion");
              Connection().registeredAppVersion = "$appVersion";
              completer.complete();
              eventBus.fire(ShowDialogEvent(
                title: "App was registered with your Home Assistant",
                body: "To start using notifications you need to restart your Home Assistant",
                positiveText: "Restart now",
                negativeText: "Later",
                onPositive: () {
                  Connection().callService(domain: "homeassistant", service: "restart", entityId: null);
                },
              ));
            });
          }).catchError((e) {
            completer.complete();
            Logger.e("Error registering the app: ${e.toString()}");
          });
      return completer.future;
    } else if (Connection().registeredAppVersion != appVersion || forceUpdate) {
      Logger.d("Registered app version is old. Registration need to be updated");
      var updateData = {
        "type": "update_registration",
        "data": _getAppRegistrationData()
      };
      Connection().sendHTTPPost(
          endPoint: "/api/webhook/${Connection().webhookId}",
          includeAuthHeader: false,
          data: json.encode(updateData)
      ).then((response) {
        Logger.d("App registration updated");
        SharedPreferences.getInstance().then((prefs) {
          prefs.setString("registered-app-version", "$appVersion");
          completer.complete();
        });
      }).catchError((e) {
        completer.complete();
        Logger.e("Error updating app registering: ${e.toString()}");
      });
      return completer.future;
    } else {
      Logger.d("App is registered");
      return Future.value();
    }
  }

  Future _getConfig() async {
    await Connection().sendSocketMessage(type: "get_config").then((data) {
      _instanceConfig = Map.from(data);
    }).catchError((e) {
      throw HAError("Error getting config: ${e}");
    });
  }

  Future _getStates() async {
    await Connection().sendSocketMessage(type: "get_states").then(
            (data) => entities.parse(data)
    ).catchError((e) {
      throw HAError("Error getting states: $e");
    });
  }

  Future _getLovelace() async {
    await Connection().sendSocketMessage(type: "lovelace/config").then((data) => _rawLovelaceData = data).catchError((e) {
      throw HAError("Error getting lovelace config: $e");
    });
  }

  Future _getUserInfo() async {
    _userName = null;
    await Connection().sendSocketMessage(type: "auth/current_user").then((data) => _userName = data["name"]).catchError((e) {
      Logger.w("Can't get user info: ${e}");
    });
  }

  Future _getServices() async {
    await Connection().sendSocketMessage(type: "get_services").then((data) => Logger.d("Services received")).catchError((e) {
      Logger.w("Can't get services: ${e}");
    });
  }

  Future _getPanels() async {
    panels.clear();
    await Connection().sendSocketMessage(type: "get_panels").then((data) {
      data.forEach((k,v) {
        String title = v['title'] == null ? "${k[0].toUpperCase()}${k.substring(1)}" : "${v['title'][0].toUpperCase()}${v['title'].substring(1)}";
        panels.add(Panel(
            id: k,
            type: v["component_name"],
            title: title,
            urlPath: v["url_path"],
            config: v["config"],
            icon: v["icon"]
        )
        );
      });
    }).catchError((e) {
      throw HAError("Error getting panels list: $e");
    });
  }

  void _handleEntityStateChange(Map eventData) {
    //TheLogger.debug( "New state for ${eventData['entity_id']}");
    if (_fetchCompleter.isCompleted) {
      Map data = Map.from(eventData);
      eventBus.fire(new StateChangedEvent(
          entityId: data["entity_id"],
          needToRebuildUI: entities.updateState(data)
      ));
    }
  }

  void _parseLovelace() {
      Logger.d("--Title: ${_rawLovelaceData["title"]}");
      ui.title = _rawLovelaceData["title"];
      int viewCounter = 0;
      Logger.d("--Views count: ${_rawLovelaceData['views'].length}");
      _rawLovelaceData["views"].forEach((rawView){
        Logger.d("----view id: ${rawView['id']}");
        HAView view = HAView(
            count: viewCounter,
            id: "${rawView['id']}",
            name: rawView['title'],
            iconName: rawView['icon']
        );

        if (rawView['badges'] != null && rawView['badges'] is List) {
          rawView['badges'].forEach((entity) {
            if (entities.isExist(entity)) {
              Entity e = entities.get(entity);
              view.badges.add(e);
            }
          });
        }

        view.cards.addAll(_createLovelaceCards(rawView["cards"] ?? []));
        ui.views.add(
            view
        );
        viewCounter += 1;
      });
  }

  List<HACard> _createLovelaceCards(List rawCards) {
    List<HACard> result = [];
    rawCards.forEach((rawCard){
      try {
        bool isThereCardOptionsInside = rawCard["card"] != null;
        HACard card = HACard(
            id: "card",
            name: isThereCardOptionsInside ? rawCard["card"]["title"] ??
                rawCard["card"]["name"] : rawCard["title"] ?? rawCard["name"],
            type: isThereCardOptionsInside
                ? rawCard["card"]['type']
                : rawCard['type'],
            columnsCount: isThereCardOptionsInside
                ? rawCard["card"]['columns'] ?? 4
                : rawCard['columns'] ?? 4,
            showName: isThereCardOptionsInside ? rawCard["card"]['show_name'] ??
                true : rawCard['show_name'] ?? true,
            showState: isThereCardOptionsInside
                ? rawCard["card"]['show_state'] ?? true
                : rawCard['show_state'] ?? true,
            showEmpty: rawCard['show_empty'] ?? true,
            stateFilter: rawCard['state_filter'] ?? [],
            states: rawCard['states'],
            content: rawCard['content']
        );
        if (rawCard["cards"] != null) {
          card.childCards = _createLovelaceCards(rawCard["cards"]);
        }
        rawCard["entities"]?.forEach((rawEntity) {
          if (rawEntity is String) {
            if (entities.isExist(rawEntity)) {
              card.entities.add(EntityWrapper(entity: entities.get(rawEntity)));
            } else {
              card.entities.add(EntityWrapper(entity: Entity.missed(rawEntity)));
            }
          } else {
            if (rawEntity["type"] == "divider") {
              card.entities.add(EntityWrapper(entity: Entity.divider()));
            } else if (rawEntity["type"] == "section") {
              card.entities.add(EntityWrapper(entity: Entity.section(rawEntity["label"] ?? "")));
            } else if (rawEntity["type"] == "call-service") {
              Map uiActionData = {
                "tap_action": {
                  "action": EntityUIAction.callService,
                  "service": rawEntity["service"],
                  "service_data": rawEntity["service_data"]
                },
                "hold_action": EntityUIAction.none
              };
              card.entities.add(EntityWrapper(
                  entity: Entity.callService(
                    icon: rawEntity["icon"],
                    name: rawEntity["name"],
                    service: rawEntity["service"],
                    actionName: rawEntity["action_name"]
                  ),
                uiAction: EntityUIAction(rawEntityData: uiActionData)
              )
              );
            } else if (rawEntity["type"] == "weblink") {
              Map uiActionData = {
                "tap_action": {
                  "action": EntityUIAction.navigate,
                  "service": rawEntity["url"]
                },
                "hold_action": EntityUIAction.none
              };
              card.entities.add(EntityWrapper(
                  entity: Entity.weblink(
                      icon: rawEntity["icon"],
                      name: rawEntity["name"],
                      url: rawEntity["url"]
                  ),
                  uiAction: EntityUIAction(rawEntityData: uiActionData)
              )
              );
            } else if (entities.isExist(rawEntity["entity"])) {
              Entity e = entities.get(rawEntity["entity"]);
              card.entities.add(
                  EntityWrapper(
                      entity: e,
                      displayName: rawEntity["name"],
                      icon: rawEntity["icon"],
                      uiAction: EntityUIAction(rawEntityData: rawEntity)
                  )
              );
            } else {
              card.entities.add(EntityWrapper(entity: Entity.missed(rawEntity["entity"])));
            }
          }
        });
        if (rawCard["entity"] != null) {
          var en = rawCard["entity"];
          if (en is String) {
            if (entities.isExist(en)) {
              Entity e = entities.get(en);
              card.linkedEntityWrapper = EntityWrapper(
                  entity: e,
                  icon: rawCard["icon"],
                  displayName: rawCard["name"],
                  uiAction: EntityUIAction(rawEntityData: rawCard)
              );
            } else {
              card.linkedEntityWrapper = EntityWrapper(entity: Entity.missed(en));
            }
          } else {
            if (entities.isExist(en["entity"])) {
              Entity e = entities.get(en["entity"]);
              card.linkedEntityWrapper = EntityWrapper(
                  entity: e,
                  icon: en["icon"],
                  displayName: en["name"],
                  uiAction: EntityUIAction(rawEntityData: rawCard)
              );
            } else {
              card.linkedEntityWrapper = EntityWrapper(entity: Entity.missed(en["entity"]));
            }
          }
        }
        result.add(card);
      } catch (e) {
          Logger.e("There was an error parsing card: ${e.toString()}");
      }
    });
    return result;
  }

  void _createUI() {
    ui = HomeAssistantUI();
    if ((Connection().useLovelace) && (_rawLovelaceData != null)) {
      Logger.d("Creating Lovelace UI");
      _parseLovelace();
    } else {
      Logger.d("Creating group-based UI");
      int viewCounter = 0;
      if (!entities.hasDefaultView) {
        HAView view = HAView(
            count: viewCounter,
            id: "group.default_view",
            name: "Home",
            childEntities: entities.filterEntitiesForDefaultView()
        );
        ui.views.add(
            view
        );
        viewCounter += 1;
      }
      entities.viewEntities.forEach((viewEntity) {
        HAView view = HAView(
            count: viewCounter,
            id: viewEntity.entityId,
            name: viewEntity.displayName,
            childEntities: viewEntity.childEntities
        );
        view.linkedEntity = viewEntity;
        ui.views.add(
            view
        );
        viewCounter += 1;
      });
    }
  }

  Widget buildViews(BuildContext context, TabController tabController) {
    return ui.build(context, tabController);
  }
}

/*
class SendMessageQueue {
  int _messageTimeout;
  List<HAMessage> _queue = [];

  SendMessageQueue(this._messageTimeout);

  void add(String message) {
    _queue.add(HAMessage(_messageTimeout, message));
  }
  
  List<String> getActualMessages() {
    _queue.removeWhere((item) => item.isExpired());
    List<String> result = [];
    _queue.forEach((haMessage){
      result.add(haMessage.message);
    });
    this.clear();
    return result;
  }
  
  void clear() {
    _queue.clear();
  }
  
}

class HAMessage {
  DateTime _timeStamp;
  int _messageTimeout;
  String message;
  
  HAMessage(this._messageTimeout, this.message) {
    _timeStamp = DateTime.now();
  }
  
  bool isExpired() {
    return DateTime.now().difference(_timeStamp).inSeconds > _messageTimeout;
  }
}*/
