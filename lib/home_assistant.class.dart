part of 'main.dart';

class HomeAssistant {
  String _hassioAPIEndpoint;
  String _hassioPassword;
  String _hassioAuthType;

  IOWebSocketChannel _hassioChannel;
  SendMessageQueue _messageQueue;

  int _currentMessageId = 0;
  int _statesMessageId = 0;
  int _servicesMessageId = 0;
  int _subscriptionMessageId = 0;
  int _configMessageId = 0;
  EntityCollection _entities;
  UIBuilder _uiBuilder;
  Map _instanceConfig = {};

  Completer _fetchCompleter;
  Completer _statesCompleter;
  Completer _servicesCompleter;
  Completer _configCompleter;
  Completer _connectionCompleter;
  Timer _connectionTimer;
  Timer _fetchTimer;

  int messageExpirationTime = 20; //seconds
  Duration fetchTimeout = Duration(seconds: 30);
  Duration connectTimeout = Duration(seconds: 10);

  String get locationName => _instanceConfig["location_name"] ?? "";
  int get viewsCount => _entities.viewList.length ?? 0;
  UIBuilder get uiBuilder => _uiBuilder;

  EntityCollection get entities => _entities;

  HomeAssistant(String url, String password, String authType) {
    _hassioAPIEndpoint = url;
    _hassioPassword = password;
    _hassioAuthType = authType;
    _entities = EntityCollection();
    _uiBuilder = UIBuilder();
    _messageQueue = SendMessageQueue(messageExpirationTime);
  }

  Future fetch() {
    if ((_fetchCompleter != null) && (!_fetchCompleter.isCompleted)) {
      TheLogger.log("Warning","Previous fetch is not complited");
    } else {
      _fetchCompleter = new Completer();
      _fetchTimer = Timer(fetchTimeout, () {
        closeConnection();
        _finishFetching({"errorCode" : 9,"errorMessage": "Connection timeout or connection issues"});
      });
      _reConnectSocket().then((r) {
        _getData();
      }).catchError((e) {
        _finishFetching(e);
      });
    }
    return _fetchCompleter.future;
  }

  closeConnection() {
    if (_hassioChannel?.closeCode == null) {
      _hassioChannel?.sink?.close();
    }
    _hassioChannel = null;
  }

  Future _reConnectSocket() {
    if ((_connectionCompleter != null) && (!_connectionCompleter.isCompleted)) {
      TheLogger.log("Debug","Previous connection is not complited");
    } else {
      if ((_hassioChannel == null) || (_hassioChannel.sink == null) || (_hassioChannel.closeCode != null)) {
        TheLogger.log("Debug", "Socket connecting...");
        _connectionCompleter = new Completer();
        _connectionTimer = Timer(connectTimeout, () {
          closeConnection();
          _finishConnecting({"errorCode" : 1,"errorMessage": "Connection timeout or connection issues"});
        });
        _hassioChannel = IOWebSocketChannel.connect(_hassioAPIEndpoint, pingInterval: Duration(seconds: 60));
        _hassioChannel.stream.handleError((e) {
          TheLogger.log("Error", "Unhandled socket error: ${e.toString()}");
        });
        _hassioChannel.stream.listen((message) =>
            _handleMessage(_connectionCompleter, message));
      } else {
        //TheLogger.log("Debug","Socket looks connected...${_hassioChannel.protocol}, ${_hassioChannel.closeCode}, ${_hassioChannel.closeReason}");
        _finishConnecting(null);
      }
    }
    return _connectionCompleter.future;
  }

  _getData() {
    _getConfig().then((result) {
      _getStates().then((result) {
        _getServices().then((result) {
          _finishFetching(null);
        }).catchError((e) {
          _finishFetching(e);
        });
      }).catchError((e) {
        _finishFetching(e);
      });
    }).catchError((e) {
      _finishFetching(e);
    });
  }

  void _finishFetching(error) {
    _fetchTimer.cancel();
    _finishConnecting(error);
    if (error != null) {
      if (!_fetchCompleter.isCompleted)
        _fetchCompleter.completeError(error);
    } else {
      if (!_fetchCompleter.isCompleted)
        _fetchCompleter.complete();
    }
  }

  void _finishConnecting(error) {
    _connectionTimer.cancel();
    if (error != null) {
      if (!_connectionCompleter.isCompleted)
        _connectionCompleter.completeError(error);
    } else {
      if (!_connectionCompleter.isCompleted)
        _connectionCompleter.complete();
    }
  }

  _handleMessage(Completer connectionCompleter, String message) {
    var data = json.decode(message);
    //TheLogger.log("Debug","[Received] => Message type: ${data['type']}");
    if (data["type"] == "auth_required") {
      _sendAuthMessageRaw('{"type": "auth","$_hassioAuthType": "$_hassioPassword"}');
    } else if (data["type"] == "auth_ok") {
      _finishConnecting(null);
      _sendSubscribe();
    } else if (data["type"] == "auth_invalid") {
      _finishFetching({"errorCode": 6, "errorMessage": "${data["message"]}"});
    } else if (data["type"] == "result") {
      if (data["id"] == _configMessageId) {
        _parseConfig(data);
      } else if (data["id"] == _statesMessageId) {
        _parseEntities(data);
      } else if (data["id"] == _servicesMessageId) {
        _parseServices(data);
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
    _reConnectSocket().then((r) {
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

  Future callService(String domain, String service, String entityId, Map<String, String> additionalParams) {
    _incrementMessageId();
    String message = '{"id": $_currentMessageId, "type": "call_service", "domain": "$domain", "service": "$service", "service_data": {"entity_id": "$entityId"';
    if (additionalParams != null) {
      additionalParams.forEach((name, value){
        message += ', "$name" : "$value"';
      });
    }
    message += '}}';
    return _sendMessageRaw(message, true);
  }

  void _handleEntityStateChange(Map eventData) {
    //TheLogger.log("Debug", "New state for ${eventData['entity_id']}");
    _entities.updateState(eventData);
    eventBus.fire(new StateChangedEvent(eventData["entity_id"], null, false));
  }

  void _parseConfig(Map data) {
    if (data["success"] == true) {
      _instanceConfig = Map.from(data["result"]);
      _configCompleter.complete();
    } else {
      _configCompleter.completeError({"errorCode": 2, "errorMessage": data["error"]["message"]});
    }
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
    _uiBuilder.build(_entities);
    _statesCompleter.complete();
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
    return _timeStamp.difference(DateTime.now()).inSeconds > _messageTimeout;
  }
}