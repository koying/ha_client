part of '../main.dart';

class EntityName extends StatelessWidget {

  final EdgeInsetsGeometry padding;
  final TextOverflow textOverflow;
  final bool wordsWrap;
  final double fontSize;
  final TextAlign textAlign;

  const EntityName({Key key, this.padding: const EdgeInsets.only(right: 10.0), this.textOverflow: TextOverflow.ellipsis, this.wordsWrap: true, this.fontSize: Sizes.nameFontSize, this.textAlign: TextAlign.left}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return GestureDetector(
      child: Padding(
        padding: padding,
        child: Text(
          "${entityModel.entityWrapper.displayName}",
          overflow: textOverflow,
          softWrap: wordsWrap,
          style: TextStyle(fontSize: fontSize),
          textAlign: textAlign,
        ),
      ),
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
    );
  }
}