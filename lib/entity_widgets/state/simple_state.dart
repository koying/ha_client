part of '../../main.dart';

class SimpleEntityState extends StatelessWidget {

  final bool expanded;
  final TextAlign textAlign;
  final EdgeInsetsGeometry padding;

  const SimpleEntityState({Key key, this.expanded: true, this.textAlign: TextAlign.right, this.padding: const EdgeInsets.fromLTRB(0.0, 0.0, Sizes.rightWidgetPadding, 0.0)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    Widget result = Padding(
        padding: padding,
        child: GestureDetector(
          child: Text(
              "${entityModel.entityWrapper.entity.state}${entityModel.entityWrapper.entity.unitOfMeasurement}",
              textAlign: textAlign,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: new TextStyle(
                fontSize: Sizes.stateFontSize,
              )),
            onLongPress: () {
              if (entityModel.handleTap) {
                switch (entityModel.entityWrapper.holdAction) {
                  case EntityTapAction.toggle: {
                    eventBus.fire(
                        ServiceCallEvent("homeassistant", "toggle", entityModel.entityWrapper.entity.entityId, null));
                    break;
                  }

                  default: {
                    eventBus.fire(
                        new ShowEntityPageEvent(entityModel.entityWrapper.entity));
                    break;
                  }
                }

              }
            },
            onTap: () {
            if (entityModel.handleTap) {
              switch (entityModel.entityWrapper.tapAction) {
                case EntityTapAction.toggle: {
                  eventBus.fire(
                      ServiceCallEvent("homeassistant", "toggle", entityModel.entityWrapper.entity.entityId, null));
                  break;
                }

                case EntityTapAction.callService: {
                  eventBus.fire(
                      ServiceCallEvent(entityModel.entityWrapper.actionService.split(".")[0], entityModel.entityWrapper.actionService.split(".")[1], null, entityModel.entityWrapper.actionServiceData));
                  break;
                }

                default: {
                  eventBus.fire(
                      new ShowEntityPageEvent(entityModel.entityWrapper.entity));
                  break;
                }
              }

            }
          }
        )
    );
    if (expanded) {
      return SizedBox(
        width: MediaQuery.of(context).size.width * 0.3,
        child: result,
      );
    } else {
      return result;
    }
  }
}
