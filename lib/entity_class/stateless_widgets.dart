part of '../main.dart';

class EntityWidgetsSizes {

}

class EntityModel extends InheritedWidget {

  const EntityModel({
    Key key,
    @required this.entity,
    @required this.handleTap,
    @required Widget child,
  }) : super(key: key, child: child);

  final Entity entity;
  final bool handleTap;

  static EntityModel of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(EntityModel);
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return true;
  }

}

class DefaultEntityContainer extends StatelessWidget {

  DefaultEntityContainer({
    Key key,
    @required this.state,
  }) : super(key: key);

  final Widget state;

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return SizedBox(
      height: entityModel.entity.widgetHeight,
      child: Row(
        children: <Widget>[
          EntityIcon(),
          Expanded(
            child: EntityName(),
          ),
          state
        ],
      ),
    );
  }

}

class EntityPageContainer extends StatelessWidget {

  EntityPageContainer({Key key, @required this.children}) : super(key: key);

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: children,
    );
  }

}

class SimpleEntityState extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return Padding(
        padding:
        EdgeInsets.fromLTRB(0.0, 0.0, entityModel.entity.rightWidgetPadding, 0.0),
        child: GestureDetector(
          child: Text(
              "${entityModel.entity.state}${entityModel.entity.unitOfMeasurement}",
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: entityModel.entity.stateFontSize,
              )),
          onTap: () => entityModel.handleTap ? eventBus.fire(new ShowEntityPageEvent(entityModel.entity)) : null,
        )
    );
  }

}

class EntityName extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.only(right: 10.0),
        child: Text(
          "${entityModel.entity.displayName}",
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(fontSize: entityModel.entity.nameFontSize),
        ),
      ),
      onTap: () => entityModel.handleTap ? eventBus.fire(new ShowEntityPageEvent(entityModel.entity)) : null,
    );
  }

}

class EntityIcon extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.fromLTRB(entityModel.entity.leftWidgetPadding, 0.0, 12.0, 0.0),
        //TODO: move createIconWidgetFromEntityData into this widget
        child: MaterialDesignIcons.createIconWidgetFromEntityData(
            entityModel.entity,
            entityModel.entity.iconSize,
            Entity.STATE_ICONS_COLORS[entityModel.entity.state] ?? Entity.STATE_ICONS_COLORS["default"]),
      ),
      onTap: () => entityModel.handleTap ? eventBus.fire(new ShowEntityPageEvent(entityModel.entity)) : null,
    );
  }

}

class LastUpdatedWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          entityModel.entity.leftWidgetPadding, 0.0, 0.0, 0.0),
      child: Text(
        '${entityModel.entity.lastUpdated}',
        textAlign: TextAlign.left,
        style:
        TextStyle(fontSize: entityModel.entity.smallFontSize, color: Colors.black26),
      ),
    );
  }

}

class EntityAttributesList extends StatelessWidget {

  EntityAttributesList({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    List<Widget> attrs = [];
    if ((entityModel.entity.attributesToShow == null) || (entityModel.entity.attributesToShow.contains("all"))) {
      entityModel.entity.attributes.forEach((name, value){
        attrs.add(
            _buildSingleAttribute(entityModel.entity, "$name", "$value")
        );
      });
    } else {
      entityModel.entity.attributesToShow.forEach((String attr) {
        String attrValue = entityModel.entity.getAttribute("$attr");
        if (attrValue != null) {
          attrs.add(
              _buildSingleAttribute(entityModel.entity, "$attr", "$attrValue")
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

  Widget _buildSingleAttribute(Entity entity, String name, String value) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(entity.leftWidgetPadding, entity.rowPadding, 0.0, 0.0),
            child: Text(
              "$name",
              textAlign: TextAlign.left,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(0.0, entity.rowPadding, entity.rightWidgetPadding, 0.0),
            child: Text(
              "$value",
              textAlign: TextAlign.right,
            ),
          ),
        )
      ],
    );
  }
}

class Badge extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    double iconSize = 26.0;
    Widget badgeIcon;
    String onBadgeTextValue;
    Color iconColor = Entity.badgeColors[entityModel.entity.domain] ?? Entity.badgeColors["default"];
    switch (entityModel.entity.domain) {
      case "sun": {
        badgeIcon = entityModel.entity.state == "below_horizon" ?
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
        onBadgeTextValue = entityModel.entity.unitOfMeasurement;
        badgeIcon = Center(
          child: Text(
            "${entityModel.entity.state}",
            overflow: TextOverflow.fade,
            softWrap: false,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17.0),
          ),
        );
        break;
      }
      case "device_tracker": {
        badgeIcon = MaterialDesignIcons.createIconWidgetFromEntityData(entityModel.entity, iconSize,Colors.black);
        onBadgeTextValue = entityModel.entity.state;
        break;
      }
      default: {
        badgeIcon = MaterialDesignIcons.createIconWidgetFromEntityData(entityModel.entity, iconSize,Colors.black);
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
              "${entityModel.entity.displayName}",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.0),
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onTap: () => eventBus.fire(new ShowEntityPageEvent(entityModel.entity))
    );
  }

}

class ClimateStateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final ClimateEntity entity = entityModel.entity;
    return Padding(
        padding:
        EdgeInsets.fromLTRB(0.0, 0.0, entityModel.entity.rightWidgetPadding, 0.0),
        child: GestureDetector(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                      "${entity.state}",
                      textAlign: TextAlign.right,
                      style: new TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: entityModel.entity.stateFontSize,
                      )),
                  Text(
                      entity.temperature!= null ? " ${entity.temperature}" : " ${entity.targetLow} - ${entity.targetHigh}",
                      textAlign: TextAlign.right,
                      style: new TextStyle(
                        fontSize: entityModel.entity.stateFontSize,
                      ))
                ],
              ),
              Text(
                  "Currently: ${entity.attributes["current_temperature"]}",
                  textAlign: TextAlign.right,
                  style: new TextStyle(
                      fontSize: entityModel.entity.stateFontSize,
                      color: Colors.black45
                  ))
            ],
          ),
          onTap: () => entityModel.handleTap ? eventBus.fire(new ShowEntityPageEvent(entity)) : null,
        )
    );
  }

}

class DateTimeStateWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    final DateTimeEntity entity = entityModel.entity;
    return Padding(
        padding:
        EdgeInsets.fromLTRB(0.0, 0.0, entity.rightWidgetPadding, 0.0),
        child: GestureDetector(
          child: Text(
              "${entity.formattedState}",
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: entity.stateFontSize,
              )),
          onTap: () => _handleStateTap(context, entity),
        )
    );
  }

  void _handleStateTap(BuildContext context, DateTimeEntity entity) {
    if (entity.hasDate) {
      _showDatePicker(context, entity).then((date) {
        if (date != null) {
          if (entity.hasTime) {
            _showTimePicker(context, entity).then((time){
              entity.setNewState({"date": "${formatDate(date, [yyyy, '-', mm, '-', dd])}", "time": "${formatDate(DateTime(1970, 1, 1, time.hour, time.minute), [HH, ':', nn])}"});
            });
          } else {
            entity.setNewState({"date": "${formatDate(date, [yyyy, '-', mm, '-', dd])}"});
          }
        }
      });
    } else if (entity.hasTime) {
      _showTimePicker(context, entity).then((time){
        if (time != null) {
          entity.setNewState({"time": "${formatDate(DateTime(1970, 1, 1, time.hour, time.minute), [HH, ':', nn])}"});
        }
      });
    } else {
      TheLogger.log("Warning", "${entity.entityId} has no date and no time");
    }
  }

  Future _showDatePicker(BuildContext context, DateTimeEntity entity) {
    return showDatePicker(
        context: context,
        initialDate: entity.dateTimeState,
        firstDate: DateTime(1970),
        lastDate: DateTime(2037) //Unix timestamp will finish at Jan 19, 2038
    );
  }

  Future _showTimePicker(BuildContext context, DateTimeEntity entity) {
    return showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(entity.dateTimeState)
    );
  }

}