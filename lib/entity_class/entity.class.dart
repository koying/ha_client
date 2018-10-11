part of '../main.dart';

class Entity {
  static const STATE_ICONS_COLORS = {
    "on": Colors.amber,
    "off": Color.fromRGBO(68, 115, 158, 1.0),
    "default": Color.fromRGBO(68, 115, 158, 1.0),
    "unavailable": Colors.black12,
    "unknown": Colors.black12,
    "playing": Colors.amber
  };
  static const badgeColors = {
    "default": Color.fromRGBO(223, 76, 30, 1.0),
    "binary_sensor": Color.fromRGBO(3, 155, 229, 1.0)
  };
  static List badgeDomains = ["alarm_control_panel", "binary_sensor", "device_tracker", "updater", "sun", "timer", "sensor"];

  Map attributes;
  String domain;
  String entityId;
  String state;
  String assumedState;
  DateTime _lastUpdated;

  List<Entity> childEntities = [];

  String get displayName =>
      attributes["friendly_name"] ?? (attributes["name"] ?? "_");



  String get deviceClass => attributes["device_class"] ?? null;
  bool get isView =>
      (domain == "group") &&
      (attributes != null ? attributes["view"] ?? false : false);
  bool get isGroup => domain == "group";
  bool get isBadge => Entity.badgeDomains.contains(domain);
  String get icon => attributes["icon"] ?? "";
  bool get isOn => state == "on";
  String get entityPicture => attributes["entity_picture"];
  String get unitOfMeasurement => attributes["unit_of_measurement"] ?? "";
  List get childEntityIds => attributes["entity_id"] ?? [];
  String get lastUpdated => _getLastUpdatedFormatted();

  Entity(Map rawData) {
    update(rawData);
  }

  void update(Map rawData) {
    attributes = rawData["attributes"] ?? {};
    domain = rawData["entity_id"].split(".")[0];
    entityId = rawData["entity_id"];
    state = rawData["state"];
    assumedState = state;
    _lastUpdated = DateTime.tryParse(rawData["last_updated"]);
  }

  EntityWidget buildWidget(BuildContext context, int widgetType) {
    return EntityWidget(
      entity: this,
      widgetType: widgetType,
    );
  }

  String getAttribute(String attributeName) {
    if (attributes != null) {
      return attributes["$attributeName"];
    }
    return null;
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
      case 'sun': {
        return _SunEntityWidgetState();
      }
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
      case "climate": {
        return _ClimateEntityWidgetState();
      }
      default: {
        return _EntityWidgetState();
      }
    }
  }
}

class _EntityWidgetState extends State<EntityWidget> {

  List<String> attributesToShow = ["all"];
  double rightWidgetPadding = 14.0;
  double leftWidgetPadding = 8.0;
  double extendedWidgetHeight = 50.0;
  double widgetHeight = 34.0;
  double iconSize = 28.0;
  double stateFontSize = 16.0;
  double nameFontSize = 16.0;
  double smallFontSize = 14.0;
  double largeFontSize = 24.0;
  double inputWidth = 160.0;
  double rowPadding = 10.0;

  @override
  Widget build(BuildContext context) {
    if (widget.widgetType == EntityWidgetType.regular) {
      return _buildMainWidget(context);
    } else if (widget.widgetType == EntityWidgetType.extended) {
      return _buildExtendedWidget(context);
    } else if (widget.widgetType == EntityWidgetType.badge) {
      return _buildBadgeWidget(context);
    } else {
      TheLogger.log("Error", "Unknown entity widget type: ${widget.widgetType}");
      return Container(width: 0.0, height: 0.0);
    }
  }

  Widget _buildExtendedWidget(BuildContext context) {
    return ListView(
      children: <Widget>[
        _buildMainWidget(context),
        _buildSecondRowWidget(),
        Divider(),
        _buildAttributesWidget()
      ],
    );
  }

  Widget _buildMainWidget(BuildContext context) {
    return SizedBox(
      height: widgetHeight,
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

  Widget _buildAttributesWidget() {
    List<Widget> attrs = [];
    if (attributesToShow.contains("all")) {
      widget.entity.attributes.forEach((name, value){
        attrs.add(
            _buildAttributeWidget("$name", "$value")
        );
      });
    } else {
      attributesToShow.forEach((String attr) {
        String attrValue = widget.entity.getAttribute("$attr");
        if (attrValue != null) {
          attrs.add(
              _buildAttributeWidget("$attr", "$attrValue")
          );
        }
      });
    }
    return Column(
      children: attrs,
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
    );
  }

  Widget _buildAttributeWidget(String name, String value) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(leftWidgetPadding, rowPadding, 0.0, 0.0),
            child: Text(
              "$name",
              textAlign: TextAlign.left,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(0.0, rowPadding, rightWidgetPadding, 0.0),
            child: Text(
              "$value",
              textAlign: TextAlign.right,
            ),
          ),
        )
      ],
    );
  }

  void openEntityPage() {
    eventBus.fire(new ShowEntityPageEvent(widget.entity));
  }

  void setNewState(newState) {
    return;
  }

  /*Widget buildAdditionalWidget() {
    return _buildSecondRowWidget();
  }*/

  Widget _buildIconWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(leftWidgetPadding, 0.0, 12.0, 0.0),
      child: MaterialDesignIcons.createIconWidgetFromEntityData(
          widget.entity,
          iconSize,
          Entity.STATE_ICONS_COLORS[widget.entity.state] ?? Entity.STATE_ICONS_COLORS["default"]),
    );
  }

  Widget _buildSecondRowWidget() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          leftWidgetPadding, smallFontSize, 0.0, 0.0),
      child: Text(
        '${widget.entity.lastUpdated}',
        textAlign: TextAlign.left,
        style:
        TextStyle(fontSize: smallFontSize, color: Colors.black26),
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
        style: TextStyle(fontSize: nameFontSize),
      ),
    );
  }

  Widget _buildActionWidget(BuildContext context) {
    return Padding(
        padding:
        EdgeInsets.fromLTRB(0.0, 0.0, rightWidgetPadding, 0.0),
        child: GestureDetector(
          child: Text(
              "${widget.entity.state}${widget.entity.unitOfMeasurement}",
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: stateFontSize,
              )),
          onTap: openEntityPage,
        )
    );
  }

  Widget _buildBadgeWidget(BuildContext context) {
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
            "${widget.entity.state}",
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
    return GestureDetector(
      child: Column(
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
      ),
      onTap: openEntityPage,
    );
  }
}
