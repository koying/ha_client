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

        case CardType.horizontalStack: {
          if (childCards.isNotEmpty) {
            List<Widget> children = [];
            childCards.forEach((card) {
              children.add(
                Flexible(
                  fit: FlexFit.tight,
                  child: card.build(context),
                )
              );
            });
            return Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          }
          return Container(height: 0.0, width: 0.0,);
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