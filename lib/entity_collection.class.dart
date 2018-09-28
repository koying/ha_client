part of 'main.dart';

class EntityCollection {

  Map<String, Entity> _entities;
  List<String> viewList;

  EntityCollection() {
    _entities = {};
    viewList = [];
  }

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

  void updateState(Map rawStateData) {
    if (isExist(rawStateData["entity_id"])) {
      updateFromRaw(rawStateData["new_state"]);
    } else {
      addFromRaw(rawStateData["new_state"]);
    }
  }

  void add(Entity entity) {
    _entities[entity.entityId] = entity;
  }

  Entity addFromRaw(Map rawEntityData) {
    Entity entity = Entity(rawEntityData);
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

}