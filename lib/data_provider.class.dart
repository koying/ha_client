part of 'main.dart';

class HADataProvider {
  String _hassioAPIEndpoint;
  String _hassioPassword;
  String _hassioAuthType;
  IOWebSocketChannel _hassioChannel;
  int _currentMessageId = 0;
  int _statesMessageId = 0;
  int _servicesMessageId = 0;
  int _subscriptionMessageId = 0;
  int _configMessageId = 0;
  Map _entitiesData = {};
  Map _servicesData = {};
  Map _uiStructure = {};
  Map _instanceConfig = {};
  Completer _fetchCompleter;
  Completer _statesCompleter;
  Completer _servicesCompleter;
  Completer _configCompleter;
  Timer _fetchingTimer;
  List _topBadgeDomains = ["alarm_control_panel", "binary_sensor", "device_tracker", "updater", "sun", "timer", "sensor"];

  Map get entities => _entitiesData;
  Map get services => _servicesData;
  Map get uiStructure => _uiStructure;
  Map get instanceConfig => _instanceConfig;

  HADataProvider(String url, String password, String authType) {
    _hassioAPIEndpoint = url;
    _hassioPassword = password;
    _hassioAuthType = authType;
  }

  Future fetch() {
    if ((_fetchCompleter != null) && (!_fetchCompleter.isCompleted)) {
      TheLogger.log("Warning","Previous fetch is not complited");
    } else {
      //TODO: Fetch timeout timer. Should be removed after #21 fix
      _fetchingTimer = Timer(Duration(seconds: 15), () {
        closeConnection();
        _fetchCompleter.completeError({"errorCode" : 1,"errorMessage": "Connection timeout"});
      });
      _fetchCompleter = new Completer();
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
    var _connectionCompleter = new Completer();
    if ((_hassioChannel == null) || (_hassioChannel.closeCode != null)) {
      TheLogger.log("Debug","Socket connecting...");
      _hassioChannel = IOWebSocketChannel.connect(_hassioAPIEndpoint);
      _hassioChannel.stream.handleError((e) {
        TheLogger.log("Error","Unhandled socket error: ${e.toString()}");
      });
      _hassioChannel.stream.listen((message) =>
          _handleMessage(_connectionCompleter, message));
    } else {
      _connectionCompleter.complete();
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

  _finishFetching(error) {
    _fetchingTimer.cancel();
    if (error != null) {
      _fetchCompleter.completeError(error);
    } else {
      _fetchCompleter.complete();
    }
  }

  _handleMessage(Completer connectionCompleter, String message) {
    var data = json.decode(message);
    //TheLogger.log("Debug","[Received] => Message type: ${data['type']}");
    if (data["type"] == "auth_required") {
      _sendMessageRaw('{"type": "auth","$_hassioAuthType": "$_hassioPassword"}');
    } else if (data["type"] == "auth_ok") {
      _sendSubscribe();
      connectionCompleter.complete();
    } else if (data["type"] == "auth_invalid") {
      connectionCompleter.completeError({"errorCode": 6, "errorMessage": "${data["message"]}"});
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
    _sendMessageRaw('{"id": $_subscriptionMessageId, "type": "subscribe_events", "event_type": "state_changed"}');
  }

  Future _getConfig() {
    _configCompleter = new Completer();
    _incrementMessageId();
    _configMessageId = _currentMessageId;
    _sendMessageRaw('{"id": $_configMessageId, "type": "get_config"}');

    return _configCompleter.future;
  }

  Future _getStates() {
    _statesCompleter = new Completer();
    _incrementMessageId();
    _statesMessageId = _currentMessageId;
    _sendMessageRaw('{"id": $_statesMessageId, "type": "get_states"}');

    return _statesCompleter.future;
  }

  Future _getServices() {
    _servicesCompleter = new Completer();
    _incrementMessageId();
    _servicesMessageId = _currentMessageId;
    _sendMessageRaw('{"id": $_servicesMessageId, "type": "get_services"}');

    return _servicesCompleter.future;
  }

  _incrementMessageId() {
    _currentMessageId += 1;
  }

  _sendMessageRaw(String message) {
    if (message.indexOf('"type": "auth"') > 0) {
      TheLogger.log("Debug", "[Sending] ==> auth request");
    } else {
      TheLogger.log("Debug", "[Sending] ==> $message");
    }
    _hassioChannel.sink.add(message);
  }

  void _handleEntityStateChange(Map eventData) {
    //TheLogger.log("Debug", "Parsing new state for ${eventData['entity_id']}");
    if (eventData["new_state"] == null) {
      TheLogger.log("Error", "No new_state found");
    } else {
      var parsedEntityData = _parseEntity(eventData["new_state"]);
      String entityId = parsedEntityData["entity_id"];
      if (_entitiesData[entityId] == null) {
        _entitiesData[entityId] = parsedEntityData;
      } else {
        _entitiesData[entityId].addAll(parsedEntityData);
      }
      eventBus.fire(new StateChangedEvent(eventData["entity_id"]));
    }
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
    if (response["success"] == false) {
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
          if (_entitiesData["$domain.$serviceName"] != null) {
            result[domain].remove(serviceName);
          }
        });
      });
      _servicesData = result;
      _servicesCompleter.complete();
    } catch (e) {
      //TODO hadle it properly
      TheLogger.log("Error","Error parsing services. But they are not used :-)");
      _servicesCompleter.complete();
    }
  }

  void _parseEntities(response) async {
    _entitiesData.clear();
    _uiStructure.clear();
    if (response["success"] == false) {
      _statesCompleter.completeError({"errorCode": 3, "errorMessage": response["error"]["message"]});
      return;
    }
    List data = response["result"];
    TheLogger.log("Debug","Parsing ${data.length} Home Assistant entities");
    List<String> viewsList = [];
    data.forEach((entity) {
      try {
        var composedEntity = _parseEntity(entity);

        if (composedEntity["attributes"] != null) {
          if ((composedEntity["domain"] == "group") &&
              (composedEntity["attributes"]["view"] == true)) {
            viewsList.add(composedEntity["entity_id"]);
          }
        }
        _entitiesData[entity["entity_id"]] = composedEntity;
      } catch (error) {
        TheLogger.log("Error","Error parsing entity: ${entity['entity_id']}");
      }
    });

    //Gethering information for UI
    TheLogger.log("Debug","Gethering views");
    int viewCounter = 0;
    viewsList.forEach((viewId) { //Each view
      try {
        Map viewStructure = {};
        viewCounter += 1;
        var viewGroupData = _entitiesData[viewId];
        if ((viewGroupData != null) && (viewGroupData["attributes"] != null)) {
          viewStructure["groups"] = {};
          viewStructure["state"] = "on";
          viewStructure["entity_id"] = viewGroupData["entity_id"];
          viewStructure["badges"] = {"children": []};
          viewStructure["attributes"] = {
              "icon": viewGroupData["attributes"]["icon"]
            };

          viewGroupData["attributes"]["entity_id"].forEach((
              entityId) { //Each entity or group in view
            Map newGroup = {};
            if (_entitiesData[entityId] != null) {
              Map cardOrEntityData = _entitiesData[entityId];
              String domain = cardOrEntityData["domain"];
              if (domain != "group") {
                if (_topBadgeDomains.contains(domain)) {
                  viewStructure["badges"]["children"].add(entityId);
                } else {
                  String autoGroupID = "$domain.$domain$viewCounter";
                  if (viewStructure["groups"]["$autoGroupID"] == null) {
                    newGroup["entity_id"] = "$domain.$domain$viewCounter";
                    newGroup["friendly_name"] = "$domain";
                    newGroup["children"] = [];
                    newGroup["children"].add(entityId);
                    viewStructure["groups"]["$autoGroupID"] =
                        Map.from(newGroup);
                  } else {
                    viewStructure["groups"]["$autoGroupID"]["children"].add(
                        entityId);
                  }
                }
              } else {
                if (cardOrEntityData["attributes"] != null) {
                  newGroup["entity_id"] = entityId;
                  newGroup["friendly_name"] = cardOrEntityData['attributes']['friendly_name'] ?? "";
                  newGroup["children"] = List<String>();
                  cardOrEntityData["attributes"]["entity_id"].forEach((
                      groupedEntityId) {
                    newGroup["children"].add(groupedEntityId);
                  });
                  viewStructure["groups"]["$entityId"] = Map.from(newGroup);
                } else {
                  TheLogger.log("Warning", "Group has no attributes to build a card: $entityId");
                }
              }
            } else {
              TheLogger.log("Warning", "Unknown entity inside view: $entityId");
            }
          });
          _uiStructure[viewId.split(".")[1]] = viewStructure;
        } else {
          TheLogger.log("Warning", "No state or attributes found for view: $viewId");
        }

      } catch (error) {
        TheLogger.log("Error","Error parsing view: $viewId");
      }
    });
    _statesCompleter.complete();
  }

  Map _parseEntity(rawData) {
    var composedEntity = Map.from(rawData);
    String entityDomain = rawData["entity_id"].split(".")[0];
    composedEntity["display_name"] = "${rawData["attributes"]!=null ? rawData["attributes"]["friendly_name"] ?? rawData["attributes"]["name"] : "_"}";
    composedEntity["domain"] = entityDomain;
    return composedEntity;
  }

  Future callService(String domain, String service, String entity_id) {
    var sendCompleter = Completer();
    //TODO: Send service call timeout timer. Should be removed after #21 fix
    Timer _sendTimer = Timer(Duration(seconds: 7), () {
      sendCompleter.completeError({"errorCode" : 8,"errorMessage": "Connection timeout"});
    });
    _reConnectSocket().then((r) {
      _incrementMessageId();
      _sendMessageRaw('{"id": $_currentMessageId, "type": "call_service", "domain": "$domain", "service": "$service", "service_data": {"entity_id": "$entity_id"}}');
      _sendTimer.cancel();
      sendCompleter.complete();
    }).catchError((e){
      _sendTimer.cancel();
      sendCompleter.completeError(e);
    });
    return sendCompleter.future;
  }
}