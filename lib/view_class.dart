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

  void addBadge(String entityId) {
    badges.addAll({entityId: Badge(entityId)});
  }

  void addEntityWithoutGroup(Entity entity) {
    String groupIdToAdd = "${entity.domain}.${entity.domain}$_count";
    if (cards[groupIdToAdd] == null) {
      addCard(groupIdToAdd, entity.domain);
    }
    cards[groupIdToAdd].addEntity(entity.entityId);
  }

  void addCard(String entityId, String friendlyName) {
    cards.addAll({"$entityId": HACard(entityId, friendlyName)});
  }

  void addCardWithEntities(String entityId, String friendlyName, List entities) {
    cards.addAll({"$entityId": HACard(entityId, friendlyName)});
    cards[entityId].addEntities(entities);
  }

}