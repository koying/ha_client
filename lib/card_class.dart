part of 'main.dart';

class HACard {
  String _entityId;
  List _entities;
  String _friendlyName;

  List get entities => _entities;
  String get friendlyName => _friendlyName;

  HACard(String groupId, String friendlyName) {
    _entityId = groupId;
    _entities = [];
    _friendlyName = friendlyName;
  }

  void addEntity(String entityId) {
    _entities.add(entityId);
  }

  void addEntities(List entities) {
    _entities.addAll(entities);
  }

}