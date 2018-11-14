part of '../main.dart';

class EntityIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return GestureDetector(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            Sizes.leftWidgetPadding, 0.0, 12.0, 0.0),
        child: MaterialDesignIcons.createIconWidgetFromEntityData(
            entityModel.entity,
            Sizes.iconSize,
            EntityColor.stateColor(entityModel.entity.state)
        ),
      ),
      onTap: () => entityModel.handleTap
          ? eventBus.fire(new ShowEntityPageEvent(entityModel.entity))
          : null,
    );
  }
}