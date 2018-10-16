part of 'main.dart';

class HomeAssistant {
  String _webSocketAPIEndpoint;
  String _password;
  String _authType;

  IOWebSocketChannel _hassioChannel;
  SendMessageQueue _messageQueue;

  int _currentMessageId = 0;
  int _statesMessageId = 0;
  int _servicesMessageId = 0;
  int _subscriptionMessageId = 0;
  int _configMessageId = 0;
  int _userInfoMessageId = 0;
  EntityCollection _entities;
  ViewBuilder _viewBuilder;
  Map _instanceConfig = {};
  String _userName;

  Completer _fetchCompleter;
  Completer _statesCompleter;
  Completer _servicesCompleter;
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
  int get viewsCount => _entities.viewList.length ?? 0;

  EntityCollection get entities => _entities;

  HomeAssistant() {
    _entities = EntityCollection();
    _messageQueue = SendMessageQueue(messageExpirationTime);
  }

  void updateConnectionSettings(String url, String password, String authType) {
    _webSocketAPIEndpoint = url;
    _password = password;
    _authType = authType;
  }

  Future fetch() {
    if ((_fetchCompleter != null) && (!_fetchCompleter.isCompleted)) {
      TheLogger.log("Warning","Previous fetch is not complited");
    } else {
      _fetchCompleter = new Completer();
      _fetchTimer = Timer(fetchTimeout, () {
        TheLogger.log("Error", "Data fetching timeout");
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
        onTimeout: () => TheLogger.log("Debug", "Socket sink closed")
      );
      await _socketSubscription.cancel();
      _hassioChannel = null;
    }

  }

  Future _connection() {
    if ((_connectionCompleter != null) && (!_connectionCompleter.isCompleted)) {
      TheLogger.log("Debug","Previous connection is not complited");
    } else {
      if ((_hassioChannel == null) || (_hassioChannel.closeCode != null)) {
        _connectionCompleter = new Completer();
        autoReconnect = false;
        disconnect().then((_){
          TheLogger.log("Debug", "Socket connecting...");
          _connectionTimer = Timer(connectTimeout, () {
            TheLogger.log("Error", "Socket connection timeout");
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
    TheLogger.log("Debug","Socket disconnected. Automatic reconnect is $autoReconnect");
    if (autoReconnect) {
      _reconnect();
    }
  }

  void _handleSocketError(e) {
    TheLogger.log("Error","Socket stream Error: $e");
    TheLogger.log("Debug","Automatic reconnect is $autoReconnect");
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
    futures.add(_getConfig());
    futures.add(_getServices());
    futures.add(_getUserInfo());
    try {
      await Future.wait(futures);
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
        TheLogger.log("Debug", "Fetch complete successful");
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
      eventBus.fire(ShowErrorEvent(error["errorMessage"], error["errorCode"]));
    }
  }

  _handleMessage(String message) {
    var data = json.decode(message);
    TheLogger.log("Debug","[Received] => ${data['type']}");
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
      } else if (data["id"] == _servicesMessageId) {
        _parseServices(data);
      } else if (data["id"] == _userInfoMessageId) {
        _parseUserInfo(data);
      } else if (data["id"] == _currentMessageId) {
        TheLogger.log("Debug","Request id:$_currentMessageId was successful");
      }
    } else if (data["type"] == "event") {
      if ((data["event"] != null) && (data["event"]["event_type"] == "state_changed")) {
        _handleEntityStateChange(data["event"]["data"]);
      } else if (data["event"] != null) {
        TheLogger.log("Warning","Unhandled event type: ${data["event"]["event_type"]}");
      } else {
        TheLogger.log("Error","Event is null: $message");
      }
    } else {
      TheLogger.log("Warning","Unknown message type: $message");
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
    TheLogger.log("Debug", "[Sending] ==> auth request");
    _hassioChannel.sink.add(message);
  }

  _sendMessageRaw(String message, bool queued) {
    var sendCompleter = Completer();
    if (queued) _messageQueue.add(message);
    _connection().then((r) {
      _messageQueue.getActualMessages().forEach((message){
        TheLogger.log("Debug", "[Sending queued] ==> $message");
        _hassioChannel.sink.add(message);
      });
      if (!queued) {
        TheLogger.log("Debug", "[Sending] ==> $message");
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
        if ((value is double) || (value is int)) {
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
    //TheLogger.log("Debug", "New state for ${eventData['entity_id']}");
    Map data = Map.from(eventData);
    _entities.updateState(data);
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
    /*if (response["success"] == false) {
      _servicesCompleter.completeError({"errorCode": 4, "errorMessage": response["error"]["message"]});
      return;
    }
    try {
      Map data = response["result"];
      Map result = {};
      TheLogger.log("Debug","Parsing ${data.length} Home Assistant service domains");
      data.forEach((domain, services) {
        result[domain] = Map.from(services);
        services.forEach((serviceName, serviceData) {
          if (_entitiesData.isExist("$domain.$serviceName")) {
            result[domain].remove(serviceName);
          }
        });
      });
      _servicesData = result;
      _servicesCompleter.complete();
    } catch (e) {
      TheLogger.log("Error","Error parsing services. But they are not used :-)");
      _servicesCompleter.complete();
    }*/
  }

  void _parseEntities(response) async {
    if (response["success"] == false) {
      _statesCompleter.completeError({"errorCode": 3, "errorMessage": response["error"]["message"]});
      return;
    }
    _entities.parse(response["result"]);
    _viewBuilder = ViewBuilder(entityCollection: _entities);
    _statesCompleter.complete();
  }

  Widget buildViews(BuildContext context) {
    return _viewBuilder.buildWidget(context);
  }

  Future<List> getHistory(String entityId) async {
    DateTime now = DateTime.now();
    //String endTime = formatDate(now, [yyyy, '-', mm, '-', dd, 'T', HH, ':', nn, ':', ss, z]);
    String startTime = formatDate(now.subtract(Duration(hours: 24)), [yyyy, '-', mm, '-', dd, 'T', HH, ':', nn, ':', ss, z]);
    TheLogger.log("Debug", "$startTime");
    String url = "$homeAssistantWebHost/api/history/period/$startTime?&filter_entity_id=$entityId&skip_initial_state";
    TheLogger.log("Debug", "$url");
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
    var _history = json.decode(historyResponse.body);
    if (_history is Map) {
      return null;
    } else if (_history is List) {
      TheLogger.log("Debug", "${_history[0].toString()}");
      return _history;
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