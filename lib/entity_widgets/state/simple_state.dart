part of '../../main.dart';

class SimpleEntityState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    return Padding(
        padding: EdgeInsets.fromLTRB(
            0.0, 0.0, Entity.rightWidgetPadding, 0.0),
        child: GestureDetector(
          child: Text(
              "${entityModel.entity.state}${entityModel.entity.unitOfMeasurement}",
              textAlign: TextAlign.right,
              style: new TextStyle(
                fontSize: Entity.stateFontSize,
              )),
          onTap: () => entityModel.handleTap
              ? eventBus.fire(new ShowEntityPageEvent(entityModel.entity))
              : null,
        ));
  }
}