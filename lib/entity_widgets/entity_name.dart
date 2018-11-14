part of '../main.dart';

class EntityName extends StatelessWidget {

  final EdgeInsetsGeometry padding;

  const EntityName({Key key, this.padding: const EdgeInsets.only(right: 10.0)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return GestureDetector(
      child: Padding(
        padding: padding,
        child: Text(
          "${entityModel.entity.displayName}",
          overflow: TextOverflow.ellipsis,
          softWrap: true,
          style: TextStyle(fontSize: Sizes.nameFontSize),
        ),
      ),
      onTap: () =>
      entityModel.handleTap
          ? eventBus.fire(new ShowEntityPageEvent(entityModel.entity))
          : null,
    );
  }
}