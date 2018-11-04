part of 'main.dart';

class HomeAssistant {
  String _webSocketAPIEndpoint;
  String _password;
  String _authType;
  bool _useLovelace;

  IOWebSocketChannel _hassioChannel;
  SendMessageQueue _messageQueue;

  int _currentMessageId = 0;
  int _statesMessageId = 0;
  int _servicesMessageId = 0;
  int _subscriptionMessageId = 0;
  int _configMessageId = 0;
  int _userInfoMessageId = 0;
  int _lovelaceMessageId = 0;
  EntityCollection entities;
  HomeAssistantUI ui;
  Map _instanceConfig = {};
  String _userName;

  Map _rawLovelaceData;

  Completer _fetchCompleter;
  Completer _statesCompleter;
  Completer _servicesCompleter;
  Completer _lovelaceCompleter;
  Completer _configCompleter;
  Completer _connectionCompleter;
  Completer _userInfoCompleter;
  Timer _connectionTimer;
  Timer _fetchTimer;
  bool autoReconnect = false;

  StreamSubscription _socketSubscription;

  int messageExpirationTime = 30; //seconds
  Duration fetchTimeout = Duration(seconds: 30);
  Duration connectTimeout = Duration(seconds: 15);

  String get locationName => _instanceConfig["location_name"] ?? "";
  String get userName => _userName ?? locationName;
  String get userAvatarText => userName.length > 0 ? userName[0] : "";
  //int get viewsCount => entities.views.length ?? 0;

  HomeAssistant() {
    entities = EntityCollection();
    _messageQueue = SendMessageQueue(messageExpirationTime);
  }

  void updateSettings(String url, String password, String authType, bool useLovelace) {
    _webSocketAPIEndpoint = url;
    _password = password;
    _authType = authType;
    _useLovelace = useLovelace;
    TheLogger.debug( "Use lovelace is $_useLovelace");
  }

  Future fetch() {
    if ((_fetchCompleter != null) && (!_fetchCompleter.isCompleted)) {
      TheLogger.warning("Previous fetch is not complited");
    } else {
      _fetchCompleter = new Completer();
      _fetchTimer = Timer(fetchTimeout, () {
        TheLogger.error( "Data fetching timeout");
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
        onTimeout: () => TheLogger.debug( "Socket sink closed")
      );
      await _socketSubscription.cancel();
      _hassioChannel = null;
    }

  }

  Future _connection() {
    if ((_connectionCompleter != null) && (!_connectionCompleter.isCompleted)) {
      TheLogger.debug("Previous connection is not complited");
    } else {
      if ((_hassioChannel == null) || (_hassioChannel.closeCode != null)) {
        _connectionCompleter = new Completer();
        autoReconnect = false;
        disconnect().then((_){
          TheLogger.debug( "Socket connecting...");
          _connectionTimer = Timer(connectTimeout, () {
            TheLogger.error( "Socket connection timeout");
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
    TheLogger.debug("Socket disconnected. Automatic reconnect is $autoReconnect");
    if (autoReconnect) {
      _reconnect();
    }
  }

  void _handleSocketError(e) {
    TheLogger.error("Socket stream Error: $e");
    TheLogger.debug("Automatic reconnect is $autoReconnect");
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
    futures.add(_getConfig());
    futures.add(_getServices());
    futures.add(_getUserInfo());
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
        TheLogger.debug( "Fetch complete successful");
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
      _sendAuthMessageRaw('{"type": "auth","$_authType": "$_password"}');
    } else if (data["type"] == "auth_ok") {
      _completeConnecting(null);
      _sendSubscribe();
    } else if (data["type"] == "auth_invalid") {
      _completeConnecting({"errorCode": 6, "errorMessage": "${data["message"]}"});
    } else if (data["type"] == "result") {
      if (data["id"] == _configMessageId) {
        _parseConfig(data);
      } else if (data["id"] == _statesMessageId) {
        _parseEntities(data);
      } else if (data["id"] == _lovelaceMessageId) {
        _handleLovelace(data);
      } else if (data["id"] == _servicesMessageId) {
        _parseServices(data);
      } else if (data["id"] == _userInfoMessageId) {
        _parseUserInfo(data);
      } else if (data["id"] == _currentMessageId) {
        TheLogger.debug("[Received] => Request id:$_currentMessageId was successful");
      }
    } else if (data["type"] == "event") {
      if ((data["event"] != null) && (data["event"]["event_type"] == "state_changed")) {
        TheLogger.debug("[Received] => ${data['type']}.${data["event"]["event_type"]}: ${data["event"]["data"]["entity_id"]}");
        _handleEntityStateChange(data["event"]["data"]);
      } else if (data["event"] != null) {
        TheLogger.warning("Unhandled event type: ${data["event"]["event_type"]}");
      } else {
        TheLogger.error("Event is null: $message");
      }
    } else {
      TheLogger.warning("Unknown message type: $message");
    }
  }

  void _sendSubscribe() {
    _incrementMessageId();
    _subscriptionMessageId = _currentMessageId;
    _sendMessageRaw('{"id": $_subscriptionMessageId, "type": "subscribe_events", "event_type": "state_changed"}', false);
  }

  Future _getConfig() {
    _configCompleter = new Completer();
    _incrementMessageId();
    _configMessageId = _currentMessageId;
    _sendMessageRaw('{"id": $_configMessageId, "type": "get_config"}', false);

    return _configCompleter.future;
  }

  Future _getStates() {
    _statesCompleter = new Completer();
    _incrementMessageId();
    _statesMessageId = _currentMessageId;
    _sendMessageRaw('{"id": $_statesMessageId, "type": "get_states"}', false);

    return _statesCompleter.future;
  }

  Future _getLovelace() {
    _lovelaceCompleter = new Completer();
    _incrementMessageId();
    _lovelaceMessageId = _currentMessageId;
    _sendMessageRaw('{"id": $_lovelaceMessageId, "type": "lovelace/config"}', false);

    return _lovelaceCompleter.future;
  }

  Future _getUserInfo() {
    _userInfoCompleter = new Completer();
    _incrementMessageId();
    _userInfoMessageId = _currentMessageId;
    _sendMessageRaw('{"id": $_userInfoMessageId, "type": "auth/current_user"}', false);

    return _userInfoCompleter.future;
  }

  Future _getServices() {
    _servicesCompleter = new Completer();
    _incrementMessageId();
    _servicesMessageId = _currentMessageId;
    _sendMessageRaw('{"id": $_servicesMessageId, "type": "get_services"}', false);

    return _servicesCompleter.future;
  }

  _incrementMessageId() {
    _currentMessageId += 1;
  }

  void _sendAuthMessageRaw(String message) {
    TheLogger.debug( "[Sending] ==> auth request");
    _hassioChannel.sink.add(message);
  }

  _sendMessageRaw(String message, bool queued) {
    var sendCompleter = Completer();
    if (queued) _messageQueue.add(message);
    _connection().then((r) {
      _messageQueue.getActualMessages().forEach((message){
        TheLogger.debug( "[Sending queued] ==> $message");
        _hassioChannel.sink.add(message);
      });
      if (!queued) {
        TheLogger.debug( "[Sending] ==> $message");
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
    String message = '{"id": $_currentMessageId, "type": "call_service", "domain": "$domain", "service": "$service", "service_data": {"entity_id": "$entityId"';
    if (additionalParams != null) {
      additionalParams.forEach((name, value){
        if ((value is double) || (value is int) || (value is List)) {
          message += ', "$name" : $value';
        } else {
          message += ', "$name" : "$value"';
        }
      });
    }
    message += '}}';
    return _sendMessageRaw(message, true);
  }

  void _handleEntityStateChange(Map eventData) {
    //TheLogger.debug( "New state for ${eventData['entity_id']}");
    Map data = Map.from(eventData);
    entities.updateState(data);
    eventBus.fire(new StateChangedEvent(data["entity_id"], null, false));
  }

  void _parseConfig(Map data) {
    if (data["success"] == true) {
      _instanceConfig = Map.from(data["result"]);
      _configCompleter.complete();
    } else {
      _configCompleter.completeError({"errorCode": 2, "errorMessage": data["error"]["message"]});
    }
  }

  void _parseUserInfo(Map data) {
    if (data["success"] == true) {
      _userName = data["result"]["name"];
    } else {
      _userName = null;
    }
    _userInfoCompleter.complete();
  }

  void _parseServices(response) {
    _servicesCompleter.complete();
  }

  void _handleLovelace(response) {
    if (response["success"] == true) {
      _rawLovelaceData = response["result"];
    } else {
      _rawLovelaceData = null;
    }
    _lovelaceCompleter.complete();
  }

  void _parseLovelace() {
      ui = HomeAssistantUI();
      TheLogger.debug("Parsing lovelace config");
      TheLogger.debug("--Title: ${_rawLovelaceData["title"]}");
      int viewCounter = 0;
      TheLogger.debug("--Views count: ${_rawLovelaceData['views'].length}");
      _rawLovelaceData["views"].forEach((rawView){
        TheLogger.debug("----view id: ${rawView['id']}");
        HAView view = HAView(
            count: viewCounter,
            id: "${rawView['id']}",
            name: rawView['title'],
            iconName: rawView['icon']
        );
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
      if (rawCard["cards"] != null) {
        TheLogger.debug("------card: ${rawCard['type']} has child cards");
        result.addAll(_createLovelaceCards(rawCard["cards"]));
      } else {
        TheLogger.debug("------card: ${rawCard['type']}");
        HACard card = HACard(
            id: "card",
            name: rawCard["title"],
            type: rawCard['type']
        );
        rawCard["entities"]?.forEach((rawEntity) {
          if (rawEntity is String) {
            if (entities.isExist(rawEntity)) {
              card.entities.add(entities.get(rawEntity));
            }
          } else {
            if (entities.isExist(rawEntity["entity"])) {
              card.entities.add(entities.get(rawEntity["entity"]));
            }
          }
        });
        if (rawCard["entity"] != null) {
          card.linkedEntity = entities.get(rawCard["entity"]);
        }
        result.add(card);
      }
    });
    return result;
  }

  void _parseEntities(response) async {
    if (response["success"] == false) {
      _statesCompleter.completeError({"errorCode": 3, "errorMessage": response["error"]["message"]});
      return;
    }
    entities.parse(response["result"]);
    _statesCompleter.complete();
  }

  void _createUI() {
    if ((_useLovelace) && (_rawLovelaceData != null)) {
      _parseLovelace();
    } else {
      ui = HomeAssistantUI();
      int viewCounter = 0;
      if (!entities.hasDefaultView) {
        TheLogger.debug( "--Default view");
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
        TheLogger.debug( "--View: ${viewEntity.entityId}");
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

  Widget buildViews(BuildContext context, bool lovelace) {
    return ui.build(context);
  }

  Future<List> getHistory(String entityId) async {
    DateTime now = DateTime.now();
    //String endTime = formatDate(now, [yyyy, '-', mm, '-', dd, 'T', HH, ':', nn, ':', ss, z]);
    String startTime = formatDate(now.subtract(Duration(hours: 24)), [yyyy, '-', mm, '-', dd, 'T', HH, ':', nn, ':', ss, z]);
    String url = "$homeAssistantWebHost/api/history/period/$startTime?&filter_entity_id=$entityId";
    TheLogger.debug( "$url");
    http.Response historyResponse;
    if (_authType == "access_token") {
      historyResponse = await http.get(url, headers: {
        "authorization": "Bearer $_password",
        "Content-Type": "application/json"
      });
    } else {
      historyResponse = await http.get(url, headers: {
        "X-HA-Access": "$_password",
        "Content-Type": "application/json"
      });
    }
    var history = json.decode(historyResponse.body);
    if (history is List) {
      TheLogger.debug( "Got ${history.first.length} history recors");
      return history;
    } else {
      return [];
    }
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