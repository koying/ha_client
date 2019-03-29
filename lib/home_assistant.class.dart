part of 'main.dart';

class HomeAssistant {

  final Connection connection = Connection();

  bool _useLovelace = false;
  //bool isSettingsLoaded = false;




  EntityCollection entities;
  HomeAssistantUI ui;
  Map _instanceConfig = {};
  String _userName;
  String hostname;
  HSVColor savedColor;

  Map _rawLovelaceData;

  List<Panel> panels = [];

  Duration fetchTimeout = Duration(seconds: 30);

  String get locationName {
    if (_useLovelace) {
      return ui?.title ?? "";
    } else {
      return _instanceConfig["location_name"] ?? "";
    }
  }
  String get userName => _userName ?? locationName;
  String get userAvatarText => userName.length > 0 ? userName[0] : "";
  bool get isNoEntities => entities == null || entities.isEmpty;
  bool get isNoViews => ui == null || ui.isEmpty;
  //int get viewsCount => entities.views.length ?? 0;

  HomeAssistant();

  Completer _connectCompleter;

  Future init() {
    if (_connectCompleter != null && !_connectCompleter.isCompleted) {
      Logger.w("Previous connection pending...");
      return _connectCompleter.future;
    }
    Logger.d("init...");
    _connectCompleter = Completer();
    connection.init(_handleEntityStateChange).then((_) {
      SharedPreferences.getInstance().then((prefs) {
        if (entities == null) entities = EntityCollection(connection.httpWebHost);
        _useLovelace = prefs.getBool('use-lovelace') ?? true;
        _connectCompleter.complete();
      }).catchError((e) => _connectCompleter.completeError(e));
    }).catchError((e) => _connectCompleter.completeError(e));
    return _connectCompleter.future;
  }

  Completer _fetchCompleter;

  Future fetch() {
    if (_fetchCompleter != null && !_fetchCompleter.isCompleted) {
      Logger.w("Previous data fetch is not completed yet");
      return _fetchCompleter.future;
    }
    _fetchCompleter = Completer();
    List<Future> futures = [];
    futures.add(_getStates());
    if (_useLovelace) {
      futures.add(_getLovelace());
    }
    futures.add(_getConfig());
    futures.add(_getServices());
    futures.add(_getUserInfo());
    futures.add(_getPanels());
    Future.wait(futures).then((_) {
      _createUI();
      Connection().sendSocketMessage(
        type: "subscribe_events",
        additionalData: {"event_type": "state_changed"},
      );
      _fetchCompleter.complete();
    }).catchError((e) {
      _fetchCompleter.completeError(e);
    });
    return _fetchCompleter.future;
  }

  Future logout() async {
    Logger.d("Logging out...");
    await connection.logout().then((_) {
      ui?.clear();
      entities?.clear();
    });
  }

  Future _getConfig() async {
    await connection.sendSocketMessage(type: "get_config").then((data) {
      _instanceConfig = Map.from(data);
    }).catchError((e) {
      throw {"errorCode": 1, "errorMessage": "Error getting config: $e"};
    });
  }

  Future _getStates() async {
    await connection.sendSocketMessage(type: "get_states").then(
            (data) => entities.parse(data)
    ).catchError((e) {
      throw {"errorCode": 1, "errorMessage": "Error getting states: $e"};
    });
  }

  Future _getLovelace() async {
    await connection.sendSocketMessage(type: "lovelace/config").then((data) => _rawLovelaceData = data).catchError((e) {
      throw {"errorCode": 1, "errorMessage": "Error getting lovelace config: $e"};
    });
  }

  Future _getUserInfo() async {
    _userName = null;
    await connection.sendSocketMessage(type: "auth/current_user").then((data) => _userName = data["name"]).catchError((e) {
      Logger.w("Can't get user info: ${e}");
    });
  }

  Future _getServices() async {
    await connection.sendSocketMessage(type: "get_services").then((data) => Logger.d("Services received")).catchError((e) {
      Logger.w("Can't get services: ${e}");
    });
  }

  Future _getPanels() async {
    panels.clear();
    await connection.sendSocketMessage(type: "get_panels").then((data) {
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
      throw {"errorCode": 1, "errorMessage": "Error getting panels list: $e"};
    });
  }

  void _handleEntityStateChange(Map eventData) {
    //TheLogger.debug( "New state for ${eventData['entity_id']}");
    Map data = Map.from(eventData);
    eventBus.fire(new StateChangedEvent(
      entityId: data["entity_id"],
      needToRebuildUI: entities.updateState(data)
    ));
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
    if ((_useLovelace) && (_rawLovelaceData != null)) {
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
