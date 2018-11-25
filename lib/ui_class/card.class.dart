part of '../main.dart';

class HACard {
  List<EntityWrapper> entities = [];
  EntityWrapper linkedEntityWrapper;
  String name;
  String id;
  String type;
  bool showName;
  bool showState;
  int columnsCount;

  HACard({
    this.name,
    this.id,
    this.linkedEntityWrapper,
    this.columnsCount: 4,
    this.showName: true,
    this.showState: true,
    @required this.type
  });

  Widget build(BuildContext context) {
      switch (type) {

        case CardType.entities: {
          return EntitiesCardWidget(
            card: this,
          );
        }

        case CardType.glance: {
          return GlanceCardWidget(
            card: this,
          );
        }

        case CardType.mediaControl: {
          return MediaControlCardWidget(
            card: this,
          );
        }

        case CardType.entityButton: {
          return EntityButtonCardWidget(
            card: this,
          );
        }

        case CardType.weatherForecast:
        case CardType.thermostat:
        case CardType.sensor:
        case CardType.plantStatus:
        case CardType.pictureEntity:
        case CardType.pictureElements:
        case CardType.picture:
        case CardType.map:
        case CardType.iframe:
        case CardType.gauge:
        case CardType.conditional:
        case CardType.alarmPanel: {
          return UnsupportedCardWidget(
            card: this,
          );
        }

        default: {
          if ((linkedEntityWrapper == null) && (entities.isNotEmpty)) {
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