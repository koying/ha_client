part of 'main.dart';

class HomeAssistant {
  String _webSocketAPIEndpoint;
  String httpWebHost;
  //String _password;
  String _token;
  String _tempToken;
  bool _useLovelace = false;
  bool isSettingsLoaded = false;

  IOWebSocketChannel _hassioChannel;
  SendMessageQueue _messageQueue;

  int _currentMessageId = 0;
  int _subscriptionMessageId = 0;
  Map<int, Completer> _messageResolver = {};
  EntityCollection entities;
  HomeAssistantUI ui;
  Map _instanceConfig = {};
  String _userName;
  String hostname;
  HSVColor savedColor;

  Map _rawLovelaceData;

  List<Panel> panels = [];

  Completer _fetchCompleter;
  Completer _connectionCompleter;
  Timer _connectionTimer;
  Timer _fetchTimer;
  bool autoReconnect = false;

  StreamSubscription _socketSubscription;

  int messageExpirationTime = 30; //seconds
  Duration fetchTimeout = Duration(seconds: 30);
  Duration connectTimeout = Duration(seconds: 15);

  String get locationName {
    if (_useLovelace) {
      return ui?.title ?? "";
    } else {
      return _instanceConfig["location_name"] ?? "";
    }
  }
  String get userName => _userName ?? locationName;
  String get userAvatarText => userName.length > 0 ? userName[0] : "";
  //int get viewsCount => entities.views.length ?? 0;

  HomeAssistant() {
    _messageQueue = SendMessageQueue(messageExpirationTime);
  }

  Future loadConnectionSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String domain = prefs.getString('hassio-domain');
    String port = prefs.getString('hassio-port');
    hostname = "$domain:$port";
    _webSocketAPIEndpoint = "${prefs.getString('hassio-protocol')}://$domain:$port/api/websocket";
    httpWebHost = "${prefs.getString('hassio-res-protocol')}://$domain:$port";
    //_password = prefs.getString('hassio-password');
    _token = prefs.getString('hassio-token');
    _useLovelace = prefs.getBool('use-lovelace') ?? true;
    if ((domain == null) || (port == null) ||
        (domain.length == 0) || (port.length == 0)) {
      throw("Check connection settings");
    } else {
      isSettingsLoaded = true;
      entities = EntityCollection(httpWebHost);
    }
  }

  /*void updateSettings(String url, String password, bool useLovelace) {
    _webSocketAPIEndpoint = url;
    _password = password;
    _useLovelace = useLovelace;
    Logger.d( "Use lovelace is $_useLovelace");
  }*/

  Future fetch() {
    if ((_fetchCompleter != null) && (!_fetchCompleter.isCompleted)) {
      Logger.w("Previous fetch is not complited");
    } else {
      Logger.d("Fetching...");
      _fetchCompleter = new Completer();
      _fetchTimer = Timer(fetchTimeout, () {
        Logger.e( "Data fetching timeout");
        disconnect().then((_) {
          _completeFetching({
            "errorCode": 9,
            "errorMessage": "Couldn't get data from server"
          });
        });
      });
      _connection().then((r) {
        _getData();
      }).catchError((e) {
        _completeFetching(e);
      });
    }
    return _fetchCompleter.future;
  }

  disconnect() async {
    if ((_hassioChannel != null) && (_hassioChannel.closeCode == null) && (_hassioChannel.sink != null)) {
      await _hassioChannel.sink.close().timeout(Duration(seconds: 3),
        onTimeout: () => Logger.d( "Socket sink closed")
      );
      await _socketSubscription.cancel();
      _hassioChannel = null;
    }

  }

  Future _connection() {
    if ((_connectionCompleter != null) && (!_connectionCompleter.isCompleted)) {
      Logger.d("Previous connection is not complited");
    } else {
      if ((_hassioChannel == null) || (_hassioChannel.closeCode != null)) {
        _connectionCompleter = new Completer();
        autoReconnect = false;
        disconnect().then((_){
          Logger.d( "Socket connecting...");
          _connectionTimer = Timer(connectTimeout, () {
            Logger.e( "Socket connection timeout");
            _handleSocketError(null);
          });
          if (_socketSubscription != null) {
            _socketSubscription.cancel();
          }
          _hassioChannel = IOWebSocketChannel.connect(
              _webSocketAPIEndpoint, pingInterval: Duration(seconds: 30));
          _socketSubscription = _hassioChannel.stream.listen(
                  (message) => _handleMessage(message),
              cancelOnError: true,
              onDone: () => _handleSocketClose(),
              onError: (e) => _handleSocketError(e)
          );
        });
      } else {
        _completeConnecting(null);
      }
    }
    return _connectionCompleter.future;
  }

  void _handleSocketClose() {
    Logger.d("Socket disconnected. Automatic reconnect is $autoReconnect");
    if (autoReconnect) {
      _reconnect();
    }
  }

  void _handleSocketError(e) {
    Logger.e("Socket stream Error: $e");
    Logger.d("Automatic reconnect is $autoReconnect");
    if (autoReconnect) {
      _reconnect();
    } else {
      disconnect().then((_) {
        _completeConnecting({
          "errorCode": 1,
          "errorMessage": "Couldn't connect to Home Assistant. Check network connection or connection settings."
        });
      });
    }
  }

  void _reconnect() {
    disconnect().then((_) {
      _connection().catchError((e){
        _completeConnecting(e);
      });
    });
  }

  _getData() async {
    List<Future> futures = [];
    futures.add(_getStates());
    if (_useLovelace) {
      futures.add(_getLovelace());
    }
    if (_token == null && _tempToken != null) {
      futures.add(_getLongLivedToken());
    }
    futures.add(_getConfig());
    futures.add(_getServices());
    futures.add(_getUserInfo());
    futures.add(_getPanels());
    try {
      await Future.wait(futures);
      _createUI();
      _completeFetching(null);
    } catch (error) {
      _completeFetching(error);
    }
  }

  void _completeFetching(error) {
    _fetchTimer.cancel();
    _completeConnecting(error);
    if (!_fetchCompleter.isCompleted) {
      if (error != null) {
        _fetchCompleter.completeError(error);
      } else {
        autoReconnect = true;
        Logger.d( "Fetch complete successful");
        _fetchCompleter.complete();
      }
    }
  }

  void _completeConnecting(error) {
    _connectionTimer.cancel();
    if (!_connectionCompleter.isCompleted) {
      if (error != null) {
        _connectionCompleter.completeError(error);
      } else {
        _connectionCompleter.complete();
      }
    } else if (error != null) {
      if (error is Error) {
        eventBus.fire(ShowErrorEvent(error.toString(), 12));
      } else {
        eventBus.fire(ShowErrorEvent(error["errorMessage"], error["errorCode"]));
      }

    }
  }

  _handleMessage(String message) {
    var data = json.decode(message);
    if (data["type"] == "auth_required") {
      Logger.d("[Received] <== ${data.toString()}");
      _sendAuth();
    } else if (data["type"] == "auth_ok") {
      Logger.d("[Received] <== ${data.toString()}");
      _completeConnecting(null);
      _sendSubscribe();
    } else if (data["type"] == "auth_invalid") {
      Logger.d("[Received] <== ${data.toString()}");
      //TODO remove token and login again
      _completeConnecting({"errorCode": 6, "errorMessage": "${data["message"]}"});
    } else if (data["type"] == "result") {
      Logger.d("[Received] <== ${data.toString()}");
      _messageResolver[data["id"]]?.complete(data);
      _messageResolver.remove(data["id"]);
    } else if (data["type"] == "event") {
      if ((data["event"] != null) && (data["event"]["event_type"] == "state_changed")) {
        Logger.d("[Received] <== ${data['type']}.${data["event"]["event_type"]}: ${data["event"]["data"]["entity_id"]}");
        _handleEntityStateChange(data["event"]["data"]);
      } else if (data["event"] != null) {
        Logger.w("Unhandled event type: ${data["event"]["event_type"]}");
      } else {
        Logger.e("Event is null: $message");
      }
    } else {
      Logger.d("[Received] <== ${data.toString()}");
    }
  }

  void _sendSubscribe() {
    _incrementMessageId();
    _subscriptionMessageId = _currentMessageId;
    _rawSend('{"id": $_subscriptionMessageId, "type": "subscribe_events", "event_type": "state_changed"}', false);
  }

  Future _getConfig() async {
    await _sendSocketMessage(type: "get_config").then((data) => _instanceConfig = Map.from(data["result"]));
  }

  Future _getStates() async {
    await _sendSocketMessage(type: "get_states").then((data) => entities.parse(data["result"]));
  }

  Future _getLongLivedToken() async {
    await _sendSocketMessage(type: "auth/long_lived_access_token", additionalData: {"client_name": "HA Client 3", "client_icon": null, "lifespan": 365}).then((data) {
      if (data['success']) {
        Logger.d("Got long-lived token: ${data['result']}");
        _token = data['result'];
        //TODO save token
      } else {
        Logger.e("Error getting long-lived token: ${data['error'].toString()}");
        //TODO DO DO something here
      }
    }).catchError((e) {
      Logger.e("Error getting long-lived token: ${e.toString()}");
      //TODO DO DO something here
    });
  }

  Future _getLovelace() async {
    await _sendSocketMessage(type: "lovelace/config").then((data) => _rawLovelaceData = data["result"]);
  }

  Future _getUserInfo() async {
    _userName = null;
    await _sendSocketMessage(type: "auth/current_user").then((data) => _userName = data["result"]["name"]);
  }

  Future _getServices() async {
    await _sendSocketMessage(type: "get_services").then((data) => Logger.d("We actually don`t need the list of servcies for now"));
  }

  Future _getPanels() async {
    panels.clear();
    await _sendSocketMessage(type: "get_panels").then((data) {
      if (data["success"]) {
        data["result"].forEach((k,v) {
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
      }
    });
  }

  _incrementMessageId() {
    _currentMessageId += 1;
  }

  void _sendAuth() {
    if (_token != null) {
      Logger.d( "Long leaved token exist");
      Logger.d( "[Sending] ==> auth request");
      _hassioChannel.sink.add('{"type": "auth","access_token": "$_token"}');
    } else if (_tempToken == null) {
      Logger.d( "No long leaved token. Need to authenticate.");
      final flutterWebviewPlugin = new FlutterWebviewPlugin();
      flutterWebviewPlugin.onUrlChanged.listen((String url) {
        Logger.d("Launched url: $url");
        if (url.startsWith("http://ha-client.homemade.systems/service/auth_callback.html")) {
          String authCode = url.split("=")[1];
          Logger.d("We have auth code. Getting temporary access token...");
          sendHTTPPost(
            endPoint: "/auth/token",
            contentType: "application/x-www-form-urlencoded",
            includeAuthHeader: false,
            data: "grant_type=authorization_code&code=$authCode&client_id=${Uri.encodeComponent('http://ha-client.homemade.systems/')}"
          ).then((response) {
            Logger.d("Gottemp token");
            _tempToken = json.decode(response)['access_token'];
            Logger.d("Closing webview...");
            flutterWebviewPlugin.close();
            Logger.d("Firing event to reload UI");
            eventBus.fire(ReloadUIEvent());
          }).catchError((e) {
            //TODO DO DO something here
            Logger.e("Error getting temp token: ${e.toString()}");
          });
        }
      });
      disconnect().then((_){
        //TODO create special error code to show "Login" in message
        _completeConnecting({"errorCode": 6, "errorMessage": "Not authenticated"});
      });
      String oauthUrl = "$httpWebHost/auth/authorize?client_id=${Uri.encodeComponent('http://ha-client.homemade.systems/')}&redirect_uri=${Uri.encodeComponent('http://ha-client.homemade.systems/service/auth_callback.html')}";
      Logger.d("OAuth url: $oauthUrl");
      eventBus.fire(StartAuthEvent(oauthUrl));
    } else if (_tempToken != null) {
      Logger.d("We have temp token. Login...");
      _hassioChannel.sink.add('{"type": "auth","access_token": "$_tempToken"}');
    } else {
      Logger.e("General login error");
      //TODO DO DO something here
    }
  }

  Future _sendSocketMessage({String type, Map additionalData, bool noId: false}) {
    Completer _completer = Completer();
    Map dataObject = {"type": "$type"};
    if (!noId) {
      _incrementMessageId();
      dataObject["id"] = _currentMessageId;
    }
    if (additionalData != null) {
      dataObject.addAll(additionalData);
    }
    _messageResolver[_currentMessageId] = _completer;
    _rawSend(json.encode(dataObject), false);
    return _completer.future;
  }

  _rawSend(String message, bool queued) {
    var sendCompleter = Completer();
    if (queued) {
      _messageQueue.add(message);
    }
    _connection().then((r) {
      _messageQueue.getActualMessages().forEach((message){
        Logger.d( "[Sending queued] ==> $message");
        _hassioChannel.sink.add(message);
      });
      if (!queued) {
        Logger.d( "[Sending] ==> $message");
        _hassioChannel.sink.add(message);
      }
      sendCompleter.complete();
    }).catchError((e){
      sendCompleter.completeError(e);
    });
    return sendCompleter.future;
  }

  Future callService(String domain, String service, String entityId, Map<String, dynamic> additionalParams) {
    _incrementMessageId();
    String message = "";
    if (entityId != null) {
      message = '{"id": $_currentMessageId, "type": "call_service", "domain": "$domain", "service": "$service", "service_data": {"entity_id": "$entityId"';
      if (additionalParams != null) {
        additionalParams.forEach((name, value) {
          if ((value is double) || (value is int) || (value is List)) {
            message += ', "$name" : $value';
          } else {
            message += ', "$name" : "$value"';
          }
        });
      }
      message += '}}';
    } else {
      message = '{"id": $_currentMessageId, "type": "call_service", "domain": "$domain", "service": "$service"';
      if (additionalParams != null && additionalParams.isNotEmpty) {
        message += ', "service_data": {';
        bool first = true;
        additionalParams.forEach((name, value) {
          if (!first) {
            message += ', ';
          }
          if ((value is double) || (value is int) || (value is List)) {
            message += '"$name" : $value';
          } else {
            message += '"$name" : "$value"';
          }
          first = false;
        });

        message += '}';
      }
      message += '}';
    }
    return _rawSend(message, true);
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

  Future<List> getHistory(String entityId) async {
    DateTime now = DateTime.now();
    //String endTime = formatDate(now, [yyyy, '-', mm, '-', dd, 'T', HH, ':', nn, ':', ss, z]);
    String startTime = formatDate(now.subtract(Duration(hours: 24)), [yyyy, '-', mm, '-', dd, 'T', HH, ':', nn, ':', ss, z]);
    String url = "$httpWebHost/api/history/period/$startTime?&filter_entity_id=$entityId";
    Logger.d("[Sending] ==> $url");
    http.Response historyResponse;
    historyResponse = await http.get(url, headers: {
        "authorization": "Bearer $_token",
        "Content-Type": "application/json"
    });
    var history = json.decode(historyResponse.body);
    if (history is List) {
      Logger.d( "[Received] <== ${history.first.length} history recors");
      return history;
    } else {
      return [];
    }
  }

  Future sendHTTPPost({String endPoint, String data, String contentType: "application/json", bool includeAuthHeader: true}) async {
    Completer completer = Completer();
    String url = "$httpWebHost$endPoint";
    Logger.d("[Sending] ==> $url");
    Map<String, String> headers = {};
    if (contentType != null) {
      headers["Content-Type"] = contentType;
    }
    if (includeAuthHeader) {
      headers["authorization"] = "Bearer $_token";
    }
    http.post(
      url,
      headers: headers,
      body: data
    ).then((response) {
      Logger.d("[Received] <== ${response.statusCode}, ${response.body}");
      if (response.statusCode == 200) {
        completer.complete(response.body);
      } else {
        completer.completeError({"code": response.statusCode, "message": "${response.body}"});
      }
    }).catchError((e) {
      completer.completeError(e);
    });

    return completer.future;
  }
}

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
}