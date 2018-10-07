part of '../main.dart';

class Entity {
  static const STATE_ICONS_COLORS = {
    "on": Colors.amber,
    "off": Color.fromRGBO(68, 115, 158, 1.0),
    "unavailable": Colors.black12,
    "unknown": Colors.black12,
    "playing": Colors.amber
  };
  static const badgeColors = {
    "default": Color.fromRGBO(223, 76, 30, 1.0),
    "binary_sensor": Color.fromRGBO(3, 155, 229, 1.0)
  };
  static List badgeDomains = ["alarm_control_panel", "binary_sensor", "device_tracker", "updater", "sun", "timer", "sensor"];
  static const RIGHT_WIDGET_PADDING = 14.0;
  static const LEFT_WIDGET_PADDING = 8.0;
  static const EXTENDED_WIDGET_HEIGHT = 50.0;
  static const WIDGET_HEIGHT = 34.0;
  static const ICON_SIZE = 28.0;
  static const STATE_FONT_SIZE = 16.0;
  static const NAME_FONT_SIZE = 16.0;
  static const SMALL_FONT_SIZE = 14.0;
  static const INPUT_WIDTH = 160.0;

  Map _attributes;
  String _domain;
  String _entityId;
  String _state;
  String assumedState;
  DateTime _lastUpdated;

  List<Entity> childEntities = [];

  String get displayName =>
      _attributes["friendly_name"] ?? (_attributes["name"] ?? "_");
  String get domain => _domain;
  String get entityId => _entityId;
  String get state => _state;
  set state(value) => _state = value;

  String get deviceClass => _attributes["device_class"] ?? null;
  bool get isView =>
      (_domain == "group") &&
      (_attributes != null ? _attributes["view"] ?? false : false);
  bool get isGroup => _domain == "group";
  bool get isBadge => Entity.badgeDomains.contains(_domain);
  String get icon => _attributes["icon"] ?? "";
  bool get isOn => state == "on";
  String get entityPicture => _attributes["entity_picture"];
  String get unitOfMeasurement => _attributes["unit_of_measurement"] ?? "";
  List get childEntityIds => _attributes["entity_id"] ?? [];
  String get lastUpdated => _getLastUpdatedFormatted();

  Entity(Map rawData) {
    update(rawData);
  }

  void update(Map rawData) {
    _attributes = rawData["attributes"] ?? {};
    _domain = rawData["entity_id"].split(".")[0];
    _entityId = rawData["entity_id"];
    _state = rawData["state"];
    assumedState = _state;
    _lastUpdated = DateTime.tryParse(rawData["last_updated"]);
  }

  EntityWidget buildWidget(BuildContext context, int widgetType) {
    return EntityWidget(
      entity: this,
      widgetType: widgetType,
    );
  }

  String _getLastUpdatedFormatted() {
    if (_lastUpdated == null) {
      return "-";
    } else {
      DateTime now = DateTime.now();
      Duration d = now.difference(_lastUpdated);
      String text;
      int v;
      if (d.inDays == 0) {
        if (d.inHours == 0) {
          if (d.inMinutes == 0) {
            text = "seconds ago";
            v = d.inSeconds;
          } else {
            text = "minutes ago";
            v = d.inMinutes;
          }
        } else {
          text = "hours ago";
          v = d.inHours;
        }
      } else {
        text = "days ago";
        v = d.inDays;
      }
      return "$v $text";
    }
  }

}

class EntityWidgetType {
  static final int regular = 1;
  static final int extended = 2;
  static final int badge = 3;
}

class EntityWidget extends StatefulWidget {

  EntityWidget({Key key, this.entity, this.widgetType}) : super(key: key);

  final Entity entity;
  final int widgetType;

  @override
  _EntityWidgetState createState() {
    switch (entity.domain) {
      case "automation":
      case "input_boolean":
      case "switch":
      case "light": {
        return _SwitchEntityWidgetState();
      }

      case "script":
      case "scene": {
        return _ButtonEntityWidgetState();
      }

      case "input_datetime": {
        return _DateTimeEntityWidgetState();
      }

      case "input_select": {
        return _SelectEntityWidgetState();
      }

      case "input_number": {
        return _SliderEntityWidgetState();
      }

      case "input_text": {
        return _TextEntityWidgetState();
      }

      default: {
        return _EntityWidgetState();
      }
    }
  }
}

class _EntityWidgetState extends State<EntityWidget> {

  @override
  Widget build(BuildContext context) {
    if (widget.widgetType == EntityWidgetType.regular) {
      return _buildMainWidget(context);
    } else if (widget.widgetType == EntityWidgetType.extended) {
      return ListView(
        children: <Widget>[
          _buildMainWidget(context),
          _buildLastUpdatedWidget()
        ],
      );
    } else if (widget.widgetType == EntityWidgetType.badge) {
      return _buildBadgeWidget(context);
    } else {
      TheLogger.log("Error", "Unknown entity widget type: ${widget.widgetType}");
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildMainWidget(BuildContext context) {
    return SizedBox(
      height: Entity.WIDGET_HEIGHT,
      child: Row(
        children: <Widget>[
          GestureDetector(
            child: _buildIconWidget(),
            onTap: widget.widgetType == EntityWidgetType.extended ? null : openEntityPage,
          ),
          Expanded(
            child: GestureDetector(
              child: _buildNameWidget(),
              onTap: widget.widgetType == EntityWidgetType.extended ? null : openEntityPage,
            ),
          ),
          _buildActionWidget(context)
        ],
      ),
    );
  }

  void openEntityPage() {
    eventBus.fire(new ShowEntityPageEvent(widget.entity));
  }

  void setNewState(newState) {
    return;
  }

  Widget buildAdditionalWidget() {
    return _buildLastUpdatedWidget();
  }

  Widget _buildIconWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(Entity.LEFT_WIDGET_PADDING, 0.0, 12.0, 0.0),
      child: MaterialDesignIcons.createIconWidgetFromEntityData(
          widget.entity,
          Entity.ICON_SIZE,
          Entity.STATE_ICONS_COLORS[widget.entity.state] ?? Colors.blueGrey),
    );
  }

  Widget _buildLastUpdatedWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          Entity.LEFT_WIDGET_PADDING, Entity.SMALL_FONT_SIZE, 0.0, 0.0),
      child: Text(
        '${widget.entity.lastUpdated}',
        textAlign: TextAlign.left,
        style:
        TextStyle(fontSize: Entity.SMALL_FONT_SIZE, color: Colors.black26),
      ),
    );
  }

  Widget _buildNameWidget() {
    return Padding(
      padding: EdgeInsets.only(right: 10.0),
      child: Text(
        "${widget.entity.displayName}",
        overflow: TextOverflow.ellipsis,
        softWrap: false,
        style: TextStyle(fontSize: Entity.NAME_FONT_SIZE),
      ),
    );
  }

  Widget _buildActionWidget(BuildContext context) {
    return Padding(
        padding:
        EdgeInsets.fromLTRB(0.0, 0.0, Entity.RIGHT_WIDGET_PADDING, 0.0),
        child: GestureDetector(
          child: Text(
              "${widget.entity.state}${widget.entity.unitOfMeasurement}",
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: Entity.STATE_FONT_SIZE,
              )),
          onTap: openEntityPage,
        )
    );
  }

  Widget _buildBadgeWidget(BuildContext context) {
    //TODO separate this by different Entity classes
    double iconSize = 26.0;
    Widget badgeIcon;
    String onBadgeTextValue;
    Color iconColor = Entity.badgeColors[widget.entity.domain] ?? Entity.badgeColors["default"];
    switch (widget.entity.domain) {
      case "sun": {
        badgeIcon = widget.entity.state == "below_horizon" ?
        Icon(
          MaterialDesignIcons.createIconDataFromIconCode(0xf0dc),
          size: iconSize,
        ) :
        Icon(
          MaterialDesignIcons.createIconDataFromIconCode(0xf5a8),
          size: iconSize,
        );
        break;
      }
      case "sensor": {
        onBadgeTextValue = widget.entity.unitOfMeasurement;
        badgeIcon = Center(
          child: Text(
            "${widget.entity.state == 'unknown' ? '-' : widget.entity.state}",
            overflow: TextOverflow.fade,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17.0),
          ),
        );
        break;
      }
      case "device_tracker": {
        badgeIcon = MaterialDesignIcons.createIconWidgetFromEntityData(widget.entity, iconSize,Colors.black);
        onBadgeTextValue = widget.entity.state;
        break;
      }
      default: {
        badgeIcon = MaterialDesignIcons.createIconWidgetFromEntityData(widget.entity, iconSize,Colors.black);
      }
    }
    Widget onBadgeText;
    if (onBadgeTextValue == null || onBadgeTextValue.length == 0) {
      onBadgeText = Container(width: 0.0, height: 0.0);
    } else {
      onBadgeText = Container(
          padding: EdgeInsets.fromLTRB(6.0, 2.0, 6.0, 2.0),
          child: Text("$onBadgeTextValue",
              style: TextStyle(fontSize: 12.0, color: Colors.white),
              textAlign: TextAlign.center, softWrap: false, overflow: TextOverflow.fade),
          decoration: new BoxDecoration(
            // Circle shape
            //shape: BoxShape.circle,
            color: iconColor,
            borderRadius: BorderRadius.circular(9.0),
          )
      );
    }
    return Column(
      children: <Widget>[
        Container(
          margin: EdgeInsets.fromLTRB(0.0, 10.0, 0.0, 10.0),
          width: 50.0,
          height: 50.0,
          decoration: new BoxDecoration(
            // Circle shape
            shape: BoxShape.circle,
            color: Colors.white,
            // The border you want
            border: new Border.all(
              width: 2.0,
              color: iconColor,
            ),
          ),
          child: Stack(
            overflow: Overflow.visible,
            children: <Widget>[
              Positioned(
                width: 46.0,
                height: 46.0,
                top: 0.0,
                left: 0.0,
                child: badgeIcon,
              ),
              Positioned(
                //width: 50.0,
                  bottom: -9.0,
                  left: -10.0,
                  right: -10.0,
                  child: Center(
                    child: onBadgeText,
                  )
              )
            ],
          ),
        ),
        Container(
          width: 60.0,
          child: Text(
            "${widget.entity.displayName}",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.0),
            softWrap: true,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
