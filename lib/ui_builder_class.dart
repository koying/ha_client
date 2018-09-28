part of 'main.dart';

class UIBuilder {
  EntityCollection _entities;
  Map<String, View> _views;
  List _topBadgeDomains = ["alarm_control_panel", "binary_sensor", "device_tracker", "updater", "sun", "timer", "sensor"];

  bool get isEmpty => _views.length == 0;
  Map<String, View> get views => _views ?? {};

  UIBuilder() {
    _views = {};
  }

  void build(EntityCollection entitiesCollection) {
    _entities = entitiesCollection;
    _views.clear();
    _createViewsContainers(entitiesCollection.viewList);
  }

  void _createViewsContainers(List<String> viewsList) {
    int counter = 0;
    viewsList.forEach((viewId) {
      counter += 1;
      _views[viewId] = View(viewId, counter);
    });
    //TODO merge this two func into one
    _createViews();
  }

  void _createViews() {
    TheLogger.log("Debug","Gethering views");
    _views.forEach((viewId, view) { //Each view
      try {
        Entity viewGroupEntity = _entities.get(viewId);
        viewGroupEntity.childEntities.forEach((
              entityId) { //Each entity or group in view
          if (_entities.isExist(entityId)) {
            Entity entityToAdd = _entities.get(entityId);
            if (!entityToAdd.isGroup) {
              if (_topBadgeDomains.contains(entityToAdd.domain)) {
                //This is badge
                view.addBadge(entityId);
              } else {
                //This is a standalone entity
                view.addEntityWithoutGroup(entityToAdd);
              }
            } else {
              view.addCardWithEntities(entityId, entityToAdd.displayName, entityToAdd.childEntities);
            }
          } else {
            TheLogger.log("Warning", "Unknown entity inside view: $entityId");
          }
        });
      } catch (error) {
        TheLogger.log("Error","Error parsing view: $viewId");
      }
    });
  }

}