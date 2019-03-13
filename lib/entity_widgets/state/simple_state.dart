part of '../../main.dart';

class SimpleEntityState extends StatelessWidget {

  final bool expanded;
  final TextAlign textAlign;
  final EdgeInsetsGeometry padding;
  final int maxLines;

  const SimpleEntityState({Key key, this.maxLines: 10, this.expanded: true, this.textAlign: TextAlign.right, this.padding: const EdgeInsets.fromLTRB(0.0, 0.0, Sizes.rightWidgetPadding, 0.0)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final entityModel = EntityModel.of(context);
    String state = entityModel.entityWrapper.entity.displayState ?? "";
    state = state.replaceAll("\n", "").replaceAll("\t", " ").trim();
    TextStyle textStyle =  TextStyle(
      fontSize: Sizes.stateFontSize,
    );
    if (entityModel.entityWrapper.entity.statelessType == StatelessEntityType.CALL_SERVICE) {
      textStyle = textStyle.apply(color: Colors.blue);
    }
    while (state.contains("  ")){
      state = state.replaceAll("  ", " ");
    }
    Widget result = Padding(
      padding: padding,
      child: Text(
        "$state ${entityModel.entityWrapper.entity.unitOfMeasurement}",
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        style: textStyle
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
