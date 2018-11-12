part of '../../main.dart';

class MediaPlayerWidget extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    final EntityModel entityModel = EntityModel.of(context);
    final MediaPlayerEntity entity = entityModel.entity;
    List<Widget> body = [];
    body.add(Stack(
      alignment: AlignmentDirectional.topEnd,
      children: <Widget>[
        _buildImage(entity),
        Positioned(
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          child: Container(
            color: Colors.black45,
            child: _buildState(entity),
          ),
        ),
        Positioned(
          bottom: 0.0,
          left: 0.0,
          right: 0.0,
          child: MediaPlayerProgressWidget()
        )
      ],
    ));
    return Column(
      children: body
    );
  }

  Widget _buildState(MediaPlayerEntity entity) {
    TextStyle style = TextStyle(
        fontSize: 14.0,
        color: Colors.white,
        fontWeight: FontWeight.normal,
        height: 1.2
    );
    List<Widget> states = [];
    states.add(Text("${entity.displayName}", style: style));
    String state = entity.state;
    if (state == null || state == "off" || state == "unavailable" || state == "idle") {
      states.add(Text("${entity.state}", style: style.apply(fontSizeDelta: 4.0),));
    }
    if (entity.attributes['media_title'] != null) {
      states.add(Text("${entity.attributes['media_title']}", style: style.apply(fontSizeDelta: 6.0, fontWeightDelta: 50),));
    }
    if (entity.attributes['media_content_type'] == "music") {
      states.add(Text("${entity.attributes['media_artist'] ?? entity.attributes['app_name']}", style: style.apply(fontSizeDelta: 4.0),));
    } else if (entity.attributes['app_name'] != null) {
      states.add(Text("${entity.attributes['app_name']}", style: style.apply(fontSizeDelta: 4.0),));
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(Sizes.leftWidgetPadding, Sizes.rowPadding, Sizes.rightWidgetPadding, Sizes.rowPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: states,
      ),
    );
  }

  Widget _buildImage(MediaPlayerEntity entity) {
    String state = entity.state;
    if (homeAssistantWebHost != null && entity.entityPicture != null && state != "off" && state != "unavailable" && state != "idle") {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Image(
            image: CachedNetworkImageProvider("$homeAssistantWebHost${entity.entityPicture}"),
            height: 240.0,
            width: 320.0,
            fit: BoxFit.fitHeight,
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

class MediaPlayerProgressWidget extends StatefulWidget {
  @override
  _MediaPlayerProgressWidgetState createState() => _MediaPlayerProgressWidgetState();
}

class _MediaPlayerProgressWidgetState extends State<MediaPlayerProgressWidget> {

  Timer _timer;

  @override
  Widget build(BuildContext context) {
    final EntityModel entityModel = EntityModel.of(context);
    final MediaPlayerEntity entity = entityModel.entity;
    double progress;
    try {
      DateTime lastUpdated = DateTime.parse(
          entity.attributes["media_position_updated_at"]).toLocal();
      Duration duration = Duration(seconds: entity._getIntAttributeValue("media_duration") ?? 1);
      Duration position = Duration(seconds: entity._getIntAttributeValue("media_position") ?? 0);
      int currentPosition = position.inSeconds;
      if (entity.state == "playing") {
        _timer?.cancel();
        _timer = Timer(Duration(seconds: 1), () {
          setState(() {
          });
        });
        int differenceInSeconds = DateTime
            .now()
            .difference(lastUpdated)
            .inSeconds;
        currentPosition = currentPosition + differenceInSeconds;
      } else {
        _timer?.cancel();
      }
      progress = currentPosition / duration.inSeconds;
      return LinearProgressIndicator(
        value: progress,
        backgroundColor: Colors.black45,
        valueColor: AlwaysStoppedAnimation<Color>(EntityColors.stateColor("on")),
      );
    } catch (e) {
      _timer?.cancel();
      progress = 0.0;
    }
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.black45,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

}