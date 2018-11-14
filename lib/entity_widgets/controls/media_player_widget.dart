part of '../../main.dart';

class MediaPlayerWidget extends StatelessWidget {

  void _setPower(MediaPlayerEntity entity) {
    if (entity.state != EntityState.unavailable && entity.state != EntityState.unknown) {
      if (entity.state == EntityState.off) {
        TheLogger.debug("${entity.entityId} turn_on");
      } else {
        TheLogger.debug("${entity.entityId} turn_off");
      }
    }
  }

  void _callAction(MediaPlayerEntity entity, String action) {
    TheLogger.debug("${entity.entityId} $action");
  }
  
  @override
  Widget build(BuildContext context) {
    final EntityModel entityModel = EntityModel.of(context);
    final MediaPlayerEntity entity = entityModel.entity;
    return Column(
      children: <Widget>[
        Stack(
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
        ),
        _buildControls(entity)
      ]
    );
  }

  Widget _buildControls(MediaPlayerEntity entity) {
    List<Widget> result = [];
    if (entity.supportTurnOn || entity.supportTurnOff) {
      result.add(
        IconButton(
          icon: Icon(Icons.power_settings_new),
          onPressed: () => _setPower(entity),
          iconSize: Sizes.iconSize,
        )
      );
    }
    if (entity.supportPreviousTrack) {
      result.add(
          IconButton(
            icon: Icon(Icons.skip_previous),
            onPressed: () => _callAction(entity, "media_previous_track"),
            iconSize: Sizes.iconSize,
          )
      );
    }
    if (entity.supportPlay || entity.supportPause) {
      if (entity.state == EntityState.playing) {
        result.add(
            IconButton(
              icon: Icon(Icons.pause_circle_outline),
              onPressed: () => _callAction(entity, "media_pause"),
              iconSize: Sizes.iconSize*1.5,
            )
        );
      } //else if (entity.state == '')

    }
    if (entity.supportNextTrack) {
      result.add(
          IconButton(
            icon: Icon(Icons.skip_next),
            onPressed: () => _callAction(entity, "media_next_track"),
            iconSize: Sizes.iconSize,
          )
      );
    }
    return Row(
      children: result,
      mainAxisAlignment: MainAxisAlignment.center,
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
    if (state == null || state == EntityState.off || state == EntityState.unavailable || state == EntityState.idle) {
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
    if (homeAssistantWebHost != null && entity.entityPicture != null && state != EntityState.off && state != EntityState.unavailable && state != EntityState.idle) {
      return Container(
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image(
              image: CachedNetworkImageProvider("$homeAssistantWebHost${entity.entityPicture}"),
              height: 240.0,
              width: 320.0,
              fit: BoxFit.contain,
            )
          ],
        ),
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            MaterialDesignIcons.createIconDataFromIconName("mdi:movie"),
            size: 150.0,
            color: EntityColor.stateColor("$state"),
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
      if (entity.state == EntityState.playing) {
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
        valueColor: AlwaysStoppedAnimation<Color>(EntityColor.stateColor(EntityState.on)),
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