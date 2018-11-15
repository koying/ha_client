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
              "${entityModel.entity.entity.state}${entityModel.entity.entity.unitOfMeasurement}",
              textAlign: textAlign,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              style: new TextStyle(
                fontSize: Sizes.stateFontSize,
              )),
          onTap: () => entityModel.handleTap
              ? eventBus.fire(new ShowEntityPageEvent(entityModel.entity.entity))
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
