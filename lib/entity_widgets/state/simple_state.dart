part of '../../main.dart';

class SimpleEntityState extends StatelessWidget {

  final bool expanded;

  const SimpleEntityState({Key key, this.expanded: true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    Widget result = Padding(
        padding: EdgeInsets.fromLTRB(0.0, 0.0, Sizes.rightWidgetPadding, 0.0),
        child: GestureDetector(
          child: Text(
              "${entityModel.entity.state}${entityModel.entity.unitOfMeasurement}",
              textAlign: TextAlign.right,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: new TextStyle(
                fontSize: Sizes.stateFontSize,
              )),
          onTap: () => entityModel.handleTap
              ? eventBus.fire(new ShowEntityPageEvent(entityModel.entity))
              : null,
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
