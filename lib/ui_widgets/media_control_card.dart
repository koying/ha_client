part of '../main.dart';

class MediaControlCardWidget extends StatelessWidget {

  final HACard card;

  const MediaControlCardWidget({
    Key key,
    this.card
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((card.linkedEntity == null) || (card.linkedEntity.entity.isHidden)) {
      return Container(width: 0.0, height: 0.0,);
    }

    return Card(
        child: EntityModel(
            entity: card.linkedEntity,
            handleTap: null,
            child: MediaPlayerWidget()
        )
    );
  }



}