part of 'main.dart';

class View {
  List<Entity> childEntitiesAsBadges;
  Map<String, CardSkeleton> childEntitiesAsCards;

  int count;
  List<Entity> entities;

  View({
    Key key,
    this.count,
    this.entities
  }) {
    childEntitiesAsBadges = [];
    childEntitiesAsCards = {};
    _composeEntities();
  }

  Widget buildWidget(BuildContext context) {
    return ViewWidget(
      badges: childEntitiesAsBadges,
      cards: childEntitiesAsCards,
    );
  }

  void _composeEntities() {
    entities.forEach((Entity entity){
      if (!entity.isGroup) {
        if (entity.isBadge) {
          childEntitiesAsBadges.add(entity);
        } else {
          String groupIdToAdd = "${entity.domain}.${entity.domain}$count";
          if (childEntitiesAsCards[groupIdToAdd] == null) {
            childEntitiesAsCards[groupIdToAdd] = CardSkeleton(
              displayName: entity.domain,
            );
          }
          childEntitiesAsCards[groupIdToAdd].childEntities.add(entity);
        }
      } else {
        childEntitiesAsCards[entity.entityId] = CardSkeleton(
          displayName: entity.displayName,
        );
        childEntitiesAsCards[entity.entityId].childEntities = entity.childEntities;
      }
    });
  }

}

class ViewWidget extends StatelessWidget {
  final List<Entity> badges;
  final Map<String, CardSkeleton> cards;
  final String displayName;

  const ViewWidget({
    Key key,
    this.badges,
    this.cards,
    this.displayName
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.amber,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: _buildChildren(context),
      ),
      onRefresh: () => _refreshData(),
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    List<Widget> result = [];

    if (badges.isNotEmpty) {
      result.insert(0,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10.0,
            runSpacing: 1.0,
            children: _buildBadges(context, badges),
          )
      );
    }

    cards.forEach((String id, CardSkeleton skeleton){
      result.add(
          HACard(
            entities: skeleton.childEntities,
            friendlyName: skeleton.displayName,
          )
      );
    });

    return result;
  }

  List<EntityWidget> _buildBadges(BuildContext context, List<Entity> badges) {
    List<EntityWidget> result = [];
    badges.forEach((Entity entity) {
      result.add(entity.buildWidget(context, EntityWidgetType.badge));
    });
    return result;
  }

  Future _refreshData() {
    Completer refreshCompleter = Completer();

    eventBus.fire(RefreshDataEvent());
    eventBus.on<RefreshDataFinishedEvent>().listen((event) {
      refreshCompleter.complete();
    });

    return refreshCompleter.future;
  }
}

class CardSkeleton {
  String displayName;
  List<Entity> childEntities;

  CardSkeleton({Key key, this.displayName, this.childEntities}) {
    childEntities = [];
  }
}