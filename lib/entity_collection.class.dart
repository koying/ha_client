part of 'main.dart';

class EntityCollection {

  Map<String, Entity> _entities;
  Map<String, dynamic> _uiStructure = {};

  List _topBadgeDomains = ["alarm_control_panel", "binary_sensor", "device_tracker", "updater", "sun", "timer", "sensor"];

  EntityCollection() {
    _entities = {};
  }

  Map<String, dynamic> get ui => _uiStructure;

  void parse(List rawData) {
    _entities.clear();
    _uiStructure.clear();

    TheLogger.log("Debug","Parsing ${rawData.length} Home Assistant entities");
    rawData.forEach((rawEntityData) {
      Entity newEntity = addFromRaw(rawEntityData);

      if (newEntity.isView) {
        _uiStructure.addAll({newEntity.entityId: {}});
      }
    });

    _createViews();
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

  void _createViews() async {
    TheLogger.log("Debug","Gethering views");
    int viewCounter = 0;
    _uiStructure.forEach((viewId, viewStructure) { //Each view
      try {
        viewCounter += 1;
        Entity viewGroupData = get(viewId);
        if (viewGroupData != null) {
          viewStructure["groups"] = {};
          viewStructure["state"] = "on";
          viewStructure["entity_id"] = viewGroupData.entityId;
          viewStructure["badges"] = {"children": []};
          viewStructure["attributes"] = {
            "icon": viewGroupData.icon
          };

          viewGroupData.childEntities.forEach((
              entityId) { //Each entity or group in view
            Map newGroup = {};
            if (isExist(entityId)) {
              Entity cardOrEntityData = get(entityId);
              if (!cardOrEntityData.isGroup) {
                if (_topBadgeDomains.contains(cardOrEntityData.domain)) {
                  viewStructure["badges"]["children"].add(entityId);
                } else {
                  String autoGroupID = "${cardOrEntityData.domain}.${cardOrEntityData.domain}$viewCounter";
                  if (viewStructure["groups"]["$autoGroupID"] == null) {
                    newGroup["entity_id"] = autoGroupID;
                    newGroup["friendly_name"] = cardOrEntityData.domain;
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
                newGroup["entity_id"] = entityId;
                newGroup["friendly_name"] = cardOrEntityData.displayName;
                newGroup["children"] = List<String>();
                cardOrEntityData.childEntities.forEach((
                    groupedEntityId) {
                  newGroup["children"].add(groupedEntityId);
                });
                viewStructure["groups"]["$entityId"] = Map.from(newGroup);
              }
            } else {
              TheLogger.log("Warning", "Unknown entity inside view: $entityId");
            }
          });
        } else {
          TheLogger.log("Warning", "No state or attributes found for view: $viewId");
        }

      } catch (error) {
        TheLogger.log("Error","Error parsing view: $viewId");
      }
    });
  }

}