part of 'main.dart';

class View {
  String _entityId;
  int _count;
  Map<String, HACard> cards;
  Map<String, Badge> badges;

  bool get isThereBadges => (badges != null) && (badges.isNotEmpty);

  View(String groupId, int viewCount) {
    _entityId = groupId;
    _count = viewCount;
    cards = {};
    badges = {};
  }

  void add(Entity entity) {
    if (!entity.isGroup) {
      _addEntityWithoutGroup(entity);
    } else {
      _addCardWithEntities(entity);
    }
  }

  void _addBadge(String entityId) {
    badges.addAll({entityId: Badge(entityId)});
  }

  void _addEntityWithoutGroup(Entity entity) {
    if (UIBuilder.isBadge(entity.domain)) {
      //This is badge
      _addBadge(entity.entityId);
    } else {
      //This is a standalone entity
      String groupIdToAdd = "${entity.domain}.${entity.domain}$_count";
      if (cards[groupIdToAdd] == null) {
        _addCard(groupIdToAdd, entity.domain);
      }
      cards[groupIdToAdd].addEntity(entity.entityId);
    }
  }

  void _addCard(String entityId, String friendlyName) {
    cards.addAll({"$entityId": HACard(entityId, friendlyName)});
  }

  void _addCardWithEntities(Entity entity) {
    cards.addAll({"${entity.entityId}": HACard(entity.entityId, entity.displayName)});
    cards[entity.entityId].addEntities(entity.childEntities);
  }

}