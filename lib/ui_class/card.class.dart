part of '../main.dart';

class HACard {
  List<Entity> entities = [];
  Entity linkedEntity;
  String name;
  String id;
  String type;

  HACard({
    this.name,
    this.id,
    this.linkedEntity,
    @required this.type
  });

  Widget build(BuildContext context) {
      switch (type) {

        case "entities": {
          return EntitiesCardWidget(
            card: this,
          );
        }

        case "media-control": {
          return UnsupportedCardWidget(
            card: this,
          );
        }

        default: {
          if ((linkedEntity == null) && (entities.isNotEmpty)) {
            return EntitiesCardWidget(
              card: this,
            );
          } else {
            return UnsupportedCardWidget(
              card: this,
            );
          }
        }

      }
  }

}