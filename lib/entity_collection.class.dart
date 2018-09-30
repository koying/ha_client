part of 'main.dart';

class EntityCollection {

  Map<String, Entity> _entities;
  List<String> viewList;

  EntityCollection() {
    _entities = {};
    viewList = [];
  }

  bool get hasDefaultView => _entities["group.default_view"] != null;

  void parse(List rawData) {
    _entities.clear();
    viewList.clear();

    TheLogger.log("Debug","Parsing ${rawData.length} Home Assistant entities");
    rawData.forEach((rawEntityData) {
      Entity newEntity = addFromRaw(rawEntityData);

      if (newEntity.isView) {
        viewList.add(newEntity.entityId);
      }
    });
  }

  Entity _createEntityInstance(rawEntityData) {
    switch (rawEntityData["entity_id"].split(".")[0]) {
      case "automation":
      case "input_boolean ":
      case "switch":
      case "light": {
        return SwitchEntity(rawEntityData);
      }

      case "script":
      case "scene": {
        return ButtonEntity(rawEntityData);
      }

      case "input_select": {
        return SelectEntity(rawEntityData);
      }

      case "input_number": {
        return SliderEntity(rawEntityData);
      }

      case "input_text": {
        return TextEntity(rawEntityData);
      }

      default: {
        return Entity(rawEntityData);
      }
    }
  }

  void updateState(Map rawStateData) {
    if (isExist(rawStateData["entity_id"])) {
      updateFromRaw(rawStateData["new_state"] ?? rawStateData["old_state"]);
    } else {
      addFromRaw(rawStateData["new_state"] ?? rawStateData["old_state"]);
    }
  }

  void add(Entity entity) {
    _entities[entity.entityId] = entity;
  }

  Entity addFromRaw(Map rawEntityData) {
    Entity entity = _createEntityInstance(rawEntityData);
    _entities[entity.entityId] = entity;
    return entity;
  }

  void updateFromRaw(Map rawEntityData) {
    //TODO pass entity in this function and call update from it
    _entities[rawEntityData["entity_id"]].update(rawEntityData);
  }

  Entity get(String entityId) {
    return _entities[entityId];
  }

  bool isExist(String entityId) {
    return _entities[entityId] != null;
  }

  Map<String,List<String>> getDefaultViewTopLevelEntities() {
    Map<String,List<String>> result = {"userGroups": [], "notGroupedEntities": []};
    List<String> entities = [];
    _entities.forEach((id, entity){
      if ((id.indexOf("group.") == 0) && (id.indexOf(".all_") == -1) && (!entity.isView)) {
        result["userGroups"].add(id);
      }
      if (!entity.isGroup) {
        entities.add(id);
      }
    });

    entities.forEach((entiyId) {
      bool foundInGroup = false;
      result["userGroups"].forEach((userGroupId) {
        if (_entities[userGroupId].childEntities.contains(entiyId)) {
          foundInGroup = true;
        }
      });
      if (!foundInGroup) {
        result["notGroupedEntities"].add(entiyId);
      }
    });

    return result;
  }

}