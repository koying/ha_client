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
      child: Text(
        "${entityModel.entityWrapper.entity.state} ${entityModel.entityWrapper.entity.unitOfMeasurement}",
        textAlign: textAlign,
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        style: new TextStyle(
          fontSize: Sizes.stateFontSize,
        )
      )
    );
    if (expanded) {
      return Flexible(
        fit: FlexFit.tight,
        flex: 2,
        child: result,
      );
    } else {
      return result;
    }
  }
}
