part of 'main.dart';

class HassioDataModel {
  String _hassioAPIEndpoint;
  String _hassioPassword;
  IOWebSocketChannel _hassioChannel;
  int _currentMssageId = 0;
  int _statesMessageId = 0;
  int _servicesMessageId = 0;
  Map _entitiesData = {};
  Map _servicesData = {};
  Map _uiStructure = {};
  Completer _fetchCompleter;
  Completer _statesCompleter;
  Completer _servicesCompleter;

  Map get entities => _entitiesData;
  Map get services => _servicesData;
  Map get uiStructure => _uiStructure;

  HassioDataModel(String url, String password) {
    _hassioAPIEndpoint = url;
    _hassioPassword = password;
  }

  Future fetch() {
    _fetchCompleter = new Completer();
    _reConnectSocket().then((r) {
      _getData();
    }).catchError((e){
      _fetchCompleter.completeError(e);
    });
    return _fetchCompleter.future;
  }

  Future _reConnectSocket() {
    var _connectionCompleter = new Completer();
    if ((_hassioChannel == null) || (_hassioChannel.closeCode != null)) {
      debugPrint("Socket connecting...");
      _hassioChannel = IOWebSocketChannel.connect(_hassioAPIEndpoint);
      _hassioChannel.stream.handleError((e) {
        debugPrint("Socket error: ${e.toString()}");
      });
      _hassioChannel.stream.listen((message) =>
          _handleMessage(_connectionCompleter, message));
    } else {
      _connectionCompleter.complete();
    }
    return _connectionCompleter.future;
  }

  _getData() {
    _getStates().then((result) {
      _getServices().then((result) {
        _fetchCompleter.complete();
      }).catchError((e) {
        _fetchCompleter.completeError(e);
      });
    }).catchError((e) {
      _fetchCompleter.completeError(e);
    });


  }

  _handleMessage(Completer connectionCompleter, String message) {
    debugPrint("<[Receive]Message from Home Assistant:");
    var data = json.decode(message);
    debugPrint("   type: ${data['type']}");
    if (data["type"] == "auth_required") {
      debugPrint("   sending auth!");
      _sendMessageRaw('{"type": "auth","api_password": "$_hassioPassword"}');
    } else if (data["type"] == "auth_ok") {
      debugPrint("   auth done");
      debugPrint("Connection done");
      connectionCompleter.complete();
    } else if (data["type"] == "auth_invalid") {
      connectionCompleter.completeError({message: "Auth error: ${data["message"]}"});
    } else if (data["type"] == "result") {
      if (data["success"] == true) {
        if (data["id"] == _statesMessageId) {
          _parseEntities(data["result"]);
          _statesCompleter.complete();
        } else if (data["id"] == _servicesMessageId) {
          _parseServices(data["result"]);
          _servicesCompleter.complete();
        } else if (data["id"] == _currentMssageId) {
          debugPrint("Request id:$_currentMssageId was successful");
        } else {
          _handleErrorMessage({"message" : "Wrong message ID"});
        }
      } else {
        _handleErrorMessage(data["error"]);
      }
    }
  }

  _handleErrorMessage(Object error) {
    debugPrint("Error: ${error.toString()}");
    if (!_statesCompleter.isCompleted) _statesCompleter.completeError(error);
    if (!_servicesCompleter.isCompleted) _servicesCompleter.completeError(error);
  }

  Future _getStates() {
    _statesCompleter = new Completer();
    _incrementMessageId();
    _statesMessageId = _currentMssageId;
    _sendMessageRaw('{"id": $_currentMssageId, "type": "get_states"}');

    return _statesCompleter.future;
  }

  Future _getServices() {
    _servicesCompleter = new Completer();
    _incrementMessageId();
    _servicesMessageId = _currentMssageId;
    _sendMessageRaw('{"id": $_currentMssageId, "type": "get_services"}');

    return _servicesCompleter.future;
  }

  _incrementMessageId() {
    _currentMssageId += 1;
  }

  _sendMessageRaw(message) {
    _reConnectSocket().then((r) {
      debugPrint(">[Send]Sending to Home Assistant:");
      debugPrint("   $message");
      _hassioChannel.sink.add(message);
    }).catchError((e){
      debugPrint("Unable to connect for sending =(");
    });


  }

  void _parseServices(Map data) {
    Map result = {};
    debugPrint("Parsing ${data.length} Home Assistant service domains");
    data.forEach((domain, services){
      result[domain] = Map.from(services);
      services.forEach((serviceName, serviceData){
        if (_entitiesData["$domain.$serviceName"] != null) {
          result[domain].remove(serviceName);
        }
      });
    });
    _servicesData = result;
  }

  void _parseEntities(List data) async {
    Map switchServices = {
      "turn_on": {},
      "turn_off": {},
      "toggle": {}
    };
    debugPrint("Parsing ${data.length} Home Assistant entities");
    data.forEach((entity) {
      var composedEntity = Map.from(entity);
      String entityDomain = entity["entity_id"].split(".")[0];
      String entityId = entity["entity_id"];

      composedEntity["display_name"] = "${entity["attributes"]!=null ? entity["attributes"]["friendly_name"] ?? entity["attributes"]["name"] : "_"}";
      composedEntity["domain"] = entityDomain;

      if ((entityDomain == "automation") || (entityDomain == "light") || (entityDomain == "switch") || (entityDomain == "script")) {
        composedEntity["services"] = Map.from(switchServices);
      }

      _entitiesData[entityId] = Map.from(composedEntity);
    });
    var defaultView = _entitiesData["group.default_view"];
    debugPrint("Gethering default view");
    if (defaultView!= null) {
      defaultView["attributes"]["entity_id"].forEach((entityId) {
        if (_entitiesData[entityId]["domain"] != "group") {
          _uiStructure[entityId] = _entitiesData[entityId];
        } else {
          _entitiesData[entityId]["attributes"]["entity_id"].forEach((groupedEntityId) {
            _uiStructure[groupedEntityId] = _entitiesData[groupedEntityId];
          });
        }
      });
    }

  }

  callService(String domain, String service, String entity_id) {
    _incrementMessageId();
    _sendMessageRaw('{"id": $_currentMssageId, "type": "call_service", "domain": "$domain", "service": "$service", "service_data": {"entity_id": "$entity_id"}}');
  }
}