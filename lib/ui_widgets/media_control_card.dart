part of '../main.dart';

class MediaControlCardWidget extends StatelessWidget {

  final HACard card;

  const MediaControlCardWidget({
    Key key,
    this.card
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((card.linkedEntity == null) || (card.linkedEntity.isHidden)) {
      return Container(width: 0.0, height: 0.0,);
    }
    List<Widget> body = [];
    body.add(Stack(
      alignment: AlignmentDirectional.topEnd,
      children: <Widget>[
        _buildImage(),
        Positioned(
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          child: Container(
            color: Colors.black45,
            child: _buildState(),
          ),
        ),
        Positioned(
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          child: _buildProgress(),
        )
      ],
    ));
    return Card(
        child: Column(
            //crossAxisAlignment: CrossAxisAlignment.center,
            children: body
        )
    );
  }

  Widget _buildProgress() {
    double progress;
    try {
      DateTime lastUpdated = DateTime.parse(
          card.linkedEntity.attributes["media_position_updated_at"]).toLocal();
      Duration duration = Duration(seconds: card.linkedEntity._getIntAttributeValue("media_duration") ?? 1);
      Duration position = Duration(seconds: card.linkedEntity._getIntAttributeValue("media_position") ?? 0);
      int currentPosition = position.inSeconds;
      if (card.linkedEntity.state == "playing") {
        int differenceInSeconds = DateTime
            .now()
            .difference(lastUpdated)
            .inSeconds;
        currentPosition = currentPosition + differenceInSeconds;
      }
      progress = currentPosition / duration.inSeconds;
      return LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.black45,
        valueColor: AlwaysStoppedAnimation<Color>(EntityColors.stateColor("on")),
      );
    } catch (e) {
      progress = 0.0;
    }
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.black45,
    );
  }

  Widget _buildState() {
    TextStyle style = TextStyle(
      fontSize: 14.0,
      color: Colors.white,
      fontWeight: FontWeight.normal,
      height: 1.2
    );
    List<Widget> states = [];
    states.add(Text("${card.linkedEntity.displayName}", style: style));
    String state = card.linkedEntity.state;
    if (state == null || state == "off" || state == "unavailable" || state == "idle") {
      states.add(Text("${card.linkedEntity.state}", style: style.apply(fontSizeDelta: 4.0),));
    } else {
      states.add(Text("${card.linkedEntity.attributes['media_title'] ?? '-'}", style: style.apply(fontSizeDelta: 6.0, fontWeightDelta: 50),));
      states.add(Text("${card.linkedEntity.attributes['media_artist'] ?? card.linkedEntity.attributes['app_name']}", style: style.apply(fontSizeDelta: 4.0),));
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(Entity.leftWidgetPadding, Entity.rowPadding, Entity.rightWidgetPadding, Entity.rowPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: states,
      ),
    );
  }

  Widget _buildImage() {
    String state = card.linkedEntity.state;
    if (homeAssistantWebHost != null && card.linkedEntity.entityPicture != null && state != "off" && state != "unavailable" && state != "idle") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image(
            image: CachedNetworkImageProvider("$homeAssistantWebHost${card.linkedEntity.entityPicture}"),
            height: 300.0,
          )
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            MaterialDesignIcons.createIconDataFromIconName("mdi:movie"),
            size: 150.0,
            color: EntityColors.stateColor("$state"),
          )
        ],
      );
      /*return Container(
        color: Colors.blue,
        height: 80.0,
      );*/
    }
  }

}