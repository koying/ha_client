part of '../main.dart';

class HACard {
  List<EntityWrapper> entities = [];
  List<HACard> childCards = [];
  EntityWrapper linkedEntityWrapper;
  String name;
  String id;
  String type;
  bool showName;
  bool showState;
  bool showEmpty;
  int columnsCount;
  List stateFilter;

  HACard({
    this.name,
    this.id,
    this.linkedEntityWrapper,
    this.columnsCount: 4,
    this.showName: true,
    this.showState: true,
    this.stateFilter: const [],
    this.showEmpty: true,
    @required this.type
  });

  List<EntityWrapper> getEntitiesToShow() {
    return entities.where((entityWrapper) {
      if (entityWrapper.entity.isHidden) {
        return false;
      }
      if (stateFilter.isNotEmpty) {
        return stateFilter.contains(entityWrapper.entity.state);
      }
      return true;
    }).toList();
  }

  Widget build(BuildContext context) {
    return CardWidget(
      card: this,
    );
  }

}