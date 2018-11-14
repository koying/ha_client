part of '../main.dart';

class EntityIcon extends StatelessWidget {

  final EdgeInsetsGeometry padding;
  final double iconSize;

  const EntityIcon({Key key, this.iconSize: Sizes.iconSize, this.padding: const EdgeInsets.fromLTRB(
      Sizes.leftWidgetPadding, 0.0, 12.0, 0.0)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return GestureDetector(
      child: Padding(
        padding: padding,
        child: MaterialDesignIcons.createIconWidgetFromEntityData(
            entityModel.entity,
            iconSize,
            EntityColor.stateColor(entityModel.entity.state)
        ),
      ),
      onTap: () => entityModel.handleTap
          ? eventBus.fire(new ShowEntityPageEvent(entityModel.entity))
          : null,
    );
  }
}