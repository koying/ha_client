part of '../main.dart';

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