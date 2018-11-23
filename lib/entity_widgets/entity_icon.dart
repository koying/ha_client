part of '../main.dart';

class EntityIcon extends StatelessWidget {

  final EdgeInsetsGeometry padding;
  final double iconSize;

  const EntityIcon({Key key, this.iconSize: Sizes.iconSize, this.padding: const EdgeInsets.fromLTRB(
      Sizes.leftWidgetPadding, 0.0, 12.0, 0.0)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final EntityWrapper entityWrapper = EntityModel.of(context).entityWrapper;
    return Padding(
      padding: padding,
      child: MaterialDesignIcons.createIconWidgetFromEntityData(
          entityWrapper,
          iconSize,
          EntityColor.stateColor(entityWrapper.entity.state)
      ),
    );
  }
}