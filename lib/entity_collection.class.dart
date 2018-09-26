part of 'main.dart';

class EntityCollection {

  Map<String, Entity> _entities;

  EntityCollection() {
    _entities = {};
  }

  void fillFromRawData(Map rawData) {
    _entities.clear();
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
  }

}