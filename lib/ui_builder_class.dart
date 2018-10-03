part of 'main.dart';

class UIBuilder {
  EntityCollection _entities;
  Map<String, View> _views;
  static List badgeDomains = ["alarm_control_panel", "binary_sensor", "device_tracker", "updater", "sun", "timer", "sensor"];

  bool get isEmpty => _views.length == 0;
  Map<String, View> get views => _views ?? {};

  UIBuilder() {
    _views = {};
  }

  static bool isBadge(String domain) {
    return badgeDomains.contains(domain);
  }

  void build(EntityCollection entitiesCollection) {
    _entities = entitiesCollection;
    _views.clear();
    if (!_entities.hasDefaultView) {
      _createDefaultView();
    }
    _createViews(entitiesCollection.viewList);
  }

  void _createDefaultView() {
    Map<String, List<String>> userGroupsList = _entities.getDefaultViewTopLevelEntities();
    View view = View("group.default_view", 0);
    userGroupsList["userGroups"].forEach((groupId){
      view.add(_entities.get(groupId));
    });
    userGroupsList["notGroupedEntities"].forEach((entityId){
      view.add(_entities.get(entityId));
    });
    _views["group.default_view"] = view;
  }

  void _createViews(List<String> viewsList) {
    int counter = 0;
    viewsList.forEach((viewId) {
      counter += 1;
      View view = View(viewId, counter);

      try {
        Entity viewGroupEntity = _entities.get(viewId);
        viewGroupEntity.childEntities.forEach((
            entityId) { //Each entity or group in view
          if (_entities.isExist(entityId)) {
            view.add(_entities.get(entityId));
          } else {
            TheLogger.log("Warning", "Unknown entity inside view: $entityId");
          }
        });
      } catch (error) {
        TheLogger.log("Error","Error parsing view: $viewId");
      }

      _views[viewId] = view;
    });
  }

}