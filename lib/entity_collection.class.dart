part of 'main.dart';

class EntityCollection {

  Map<String, Entity> _allEntities;
  Map<String, Entity> views;

  bool get isEmpty => _allEntities.isEmpty;

  EntityCollection() {
    _allEntities = {};
    views = {};
  }

  bool get hasDefaultView => _allEntities["group.default_view"] != null;

  void parse(List rawData) {
    _allEntities.clear();
    views.clear();

    TheLogger.log("Debug","Parsing ${rawData.length} Home Assistant entities");
    rawData.forEach((rawEntityData) {
      addFromRaw(rawEntityData);
    });
    _allEntities.forEach((entityId, entity){
      if ((entity.isGroup) && (entity.childEntityIds != null)) {
        entity.childEntities = getAll(entity.childEntityIds);
      }
      if (entity.isView) {
        views[entityId] = entity;
      }
    });
  }

  Entity _createEntityInstance(rawEntityData) {
    switch (rawEntityData["entity_id"].split(".")[0]) {
      case 'sun': {
        return SunEntity(rawEntityData);
      }
      case "automation":
      case "input_boolean":
      case "switch": {
        return SwitchEntity(rawEntityData);
      }
      case "light": {
        return LightEntity(rawEntityData);
      }
      case "script":
      case "scene": {
        return ButtonEntity(rawEntityData);
      }
      case "input_datetime": {
        return DateTimeEntity(rawEntityData);
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
      case "climate": {
        return ClimateEntity(rawEntityData);
      }
      case "cover": {
        return CoverEntity(rawEntityData);
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
    _allEntities[entity.entityId] = entity;
  }

  Entity addFromRaw(Map rawEntityData) {
    Entity entity = _createEntityInstance(rawEntityData);
    _allEntities[entity.entityId] = entity;
    return entity;
  }

  void updateFromRaw(Map rawEntityData) {
    get("${rawEntityData["entity_id"]}")?.update(rawEntityData);
  }

  Entity get(String entityId) {
    return _allEntities[entityId];
  }

  List<Entity> getAll(List ids) {
    List<Entity> result = [];
    ids.forEach((id){
      Entity en = get(id);
      if (en != null) {
        result.add(en);
      }
    });
    return result;
  }

  bool isExist(String entityId) {
    return _allEntities[entityId] != null;
  }

  Map<String,List<String>> getDefaultViewTopLevelEntities() {
    Map<String,List<String>> result = {"userGroups": [], "notGroupedEntities": []};
    List<String> entities = [];
    _allEntities.forEach((id, entity){
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
        if (_allEntities[userGroupId].childEntityIds.contains(entiyId)) {
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